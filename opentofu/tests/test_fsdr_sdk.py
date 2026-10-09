#!/usr/bin/env python3
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
"""Check recovery request payloads against the OCI SDK without credentials."""

import importlib
import inspect
import unittest

try:
    import oci
except ImportError:
    oci = None

import test_fsdr_recovery as fixtures
import fsdr


def validate_model(cls, payload):
    models = importlib.import_module(".".join(cls.__module__.split(".")[:3]))
    if hasattr(cls, "get_subtype"):
        cls = getattr(models, cls.get_subtype(payload))
    model = cls()
    reverse = {json_key: name for name, json_key in model.attribute_map.items()}
    unknown = set(payload) - set(reverse)
    if unknown:
        raise AssertionError(f"{cls.__name__}: unsupported fields {unknown}")
    for key, value in payload.items():
        field = reverse[key]
        setattr(model, field, value)
        typename = model.swagger_types[field]
        if value is None:
            continue
        if typename.startswith("list[") and typename[5:-1][:1].isupper():
            for item in value:
                validate_model(getattr(models, typename[5:-1]), item)
        elif typename[:1].isupper():
            validate_model(getattr(models, typename), value)


@unittest.skipUnless(oci, "OCI SDK is installed on the deployment host")
class SDKContractTests(unittest.TestCase):
    def test_recovery_and_plan_request_signatures(self):
        recovery, api, _ = fixtures.RecoveryTests().recovery()
        recovery.configure_plans("group-1")
        clients = {"database": oci.database.DatabaseClient, "dr": oci.disaster_recovery.DisasterRecoveryClient,
                   "block": oci.core.BlockstorageClient}
        for _, service, method, args, kwargs in api.calls:
            operation = getattr(clients[service], method)
            signature = inspect.signature(operation)
            binding = signature.bind(None, *args, **kwargs)
            for parameter, value in binding.arguments.items():
                if parameter.endswith("_details"):
                    self.assertIsInstance(value, dict, method)
                elif parameter.endswith("_id"):
                    self.assertIsInstance(value, str, method)
            if method in ("update_dr_plan", "refresh_dr_plan", "verify_dr_plan"):
                model = {"update_dr_plan": oci.disaster_recovery.models.UpdateDrPlanDetails,
                         "refresh_dr_plan": oci.disaster_recovery.models.RefreshDrPlanDetails,
                         "verify_dr_plan": oci.disaster_recovery.models.VerifyDrPlanDetails}[method]
                validate_model(model, args[0])

    def test_storage_request_models_and_member_payloads(self):
        api = fixtures.StorageAPI()
        api.volumes = {"volume": {"availability_domain": "region-0-ad"}}
        recovery = fsdr.Preparation(fixtures.CONFIG, "region-0", api, fixtures.K8s())
        members = recovery.block_members({"volume"})
        for _, _, method, args, _ in api.calls:
            if method == "create_volume_group":
                validate_model(oci.core.models.CreateVolumeGroupDetails, args[0])
        adapter = object.__new__(fsdr.OCI)
        adapter.sdk = oci
        payload = adapter.members_payload([recovery.oke_member()] + members)
        validate_model(oci.disaster_recovery.models.UpdateDrProtectionGroupDetails, {"members": payload})
        file_member = {"member_id": "filesystem", "member_type": "FILE_SYSTEM", "destination_availability_domain": "region-1-ad",
                       "export_mappings": [{"export_id": "export", "destination_mount_target_id": "mount"}]}
        validate_model(oci.disaster_recovery.models.UpdateDrProtectionGroupDetails, {"members": adapter.members_payload([file_member])})

    def test_filesystem_request_models(self):
        api = fixtures.FileAPI()
        recovery = fsdr.Preparation(fixtures.CONFIG, "region-0", api, fixtures.K8s())
        recovery.file_members({"ocid1.filesystem.oc1.region-0.source"})
        models = {"create_network_security_group": oci.core.models.CreateNetworkSecurityGroupDetails,
                  "add_network_security_group_security_rules": oci.core.models.AddNetworkSecurityGroupSecurityRulesDetails,
                  "create_mount_target": oci.file_storage.models.CreateMountTargetDetails,
                  "create_file_system": oci.file_storage.models.CreateFileSystemDetails,
                  "create_replication": oci.file_storage.models.CreateReplicationDetails}
        for _, service, method, args, kwargs in api.calls:
            client = oci.file_storage.FileStorageClient if service == "file" else oci.core.VirtualNetworkClient
            inspect.signature(getattr(client, method)).bind(None, *args, **kwargs)
            if method in models:
                validate_model(models[method], args[1] if method == "add_network_security_group_security_rules" else args[0])
