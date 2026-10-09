#!/usr/bin/env python3
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

import copy
import json
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "cfgmgt/recovery"))
import fsdr
import bootstrap

CONFIG = {
    "app_namespace": "obaas", "namespaces": ["obaas"], "compartment_id": "compartment", "label": "test-dr",
    "namespace": "object-namespace",
    "node_counts": {"cpu": 3, "gpu": 1}, "standby_node_counts": {"cpu": 1, "gpu": 0},
    "backup_schedule": "FREQ=HOURLY;INTERVAL=1", "backup_retention": 24,
    "plan_types": ["SWITCHOVER", "START_DRILL", "STOP_DRILL"], "groups": {"region-0": "group-0", "region-1": "group-1"},
    "clusters": {region: {"database_id": region + "-adb", "cluster_id": region + "-oke",
                           "node_pools": {"cpu": region + "-cpu"}, "lb_id": region + "-lb", "lb_ip": "192.0.2." + str(index + 10),
                           "lb_nsg_id": region + "-nsg", "public_subnet_id": region + "-public",
                           "subnet_id": region + "-private", "availability_domain": region + "-ad",
                           "repository_host": region + ".ocir.io", "backup_bucket": region + "-backup"}
                 for index, region in enumerate(("region-0", "region-1"))},
}


class API:
    def __init__(self, role="PRIMARY"):
        self.role = role
        self.calls = []
        self.groups = {}
        self.plans = [{"id": "plan-" + kind, "display_name": "test-dr-" + kind.lower() + "-region-1", "type": kind, "lifecycle_state": "ACTIVE", "plan_groups": [
            {"id": "precheck", "type": "BUILT_IN_PRECHECK", "display_name": "Prechecks", "steps": []},
            {"id": "restore", "type": "BUILT_IN", "display_name": "Restore", "steps": []}]} for kind in CONFIG["plan_types"]]

    def members_payload(self, members):
        return fsdr.camel_payload([{key: value for key, value in member.items() if value is not None} for member in members])

    def call(self, region, service, method, *args, **kwargs):
        self.calls.append((region, service, method, copy.deepcopy(args), kwargs))
        if method == "get_autonomous_database":
            return {"role": self.role, "lifecycle_state": "AVAILABLE"}
        if method == "get_dr_protection_group":
            return copy.deepcopy(self.groups[region])
        if method == "list_dr_plan_executions":
            return []
        if method == "update_dr_protection_group":
            assert isinstance(args[0], dict) and isinstance(args[1], str)
            self.groups[region]["members"] = [{"member_id": item["memberId"], "member_type": item["memberType"]} for item in args[0]["members"]]
        if method == "list_dr_plans":
            assert args == (CONFIG["groups"][region],)
            return copy.deepcopy(self.plans)
        if method == "get_dr_plan":
            return copy.deepcopy(next(item for item in self.plans if item["id"] == args[0]))
        if method in ("refresh_dr_plan", "verify_dr_plan"):
            assert args[0] == {"type": "DEFAULT"}
        if method == "update_dr_plan":
            assert isinstance(args[0], dict) and args[1].startswith("plan-")
        if method.startswith("list_"):
            return []
        return {}


class K8s:
    def __init__(self):
        self.items = {}

    def get(self, resource, namespace=None):
        return copy.deepcopy(self.items.get((resource, namespace), {"items": []}))


class StorageAPI(API):
    def __init__(self):
        super().__init__()
        self.volumes = {}
        self.volume_groups = []

    def call(self, region, service, method, *args, **kwargs):
        if service != "block":
            return super().call(region, service, method, *args, **kwargs)
        self.calls.append((region, service, method, copy.deepcopy(args), kwargs))
        if method == "list_volume_groups":
            return copy.deepcopy(self.volume_groups)
        if method == "get_volume":
            return self.volumes[args[0]]
        if method == "create_volume_group":
            payload = args[0]
            group = {"id": "vg-created", "availability_domain": payload["availabilityDomain"], "lifecycle_state": "AVAILABLE",
                     "volume_ids": payload["sourceDetails"]["volumeIds"], "freeform_tags": payload["freeformTags"],
                     "volume_group_replicas": [{"availability_domain": replica["availabilityDomain"], "display_name": replica["displayName"],
                                                 "volume_group_replica_id": "replica"} for replica in payload["volumeGroupReplicas"]]}
            self.volume_groups.append(group)
            return copy.deepcopy(group)
        if method == "update_volume_group":
            group = next(item for item in self.volume_groups if item["id"] == args[0])
            if "volumeIds" in args[1]:
                group["volume_ids"] = args[1]["volumeIds"]
            if "volumeGroupReplicas" in args[1]:
                group["volume_group_replicas"] = [{"availability_domain": replica["availabilityDomain"], "display_name": replica["displayName"],
                                                   "volume_group_replica_id": "replica"} for replica in args[1]["volumeGroupReplicas"]]
            return group
        if method == "get_volume_group":
            return copy.deepcopy(next(item for item in self.volume_groups if item["id"] == args[0]))
        if method == "get_volume_group_replica":
            return {"lifecycle_state": "AVAILABLE", "time_last_synced": "2026-10-07T12:00:00Z"}
        raise AssertionError(method)


class FileAPI(API):
    def __init__(self):
        super().__init__()
        self.mounts, self.replications = [], []

    def call(self, region, service, method, *args, **kwargs):
        self.calls.append((region, service, method, copy.deepcopy(args), kwargs))
        if method == "list_mount_targets":
            return copy.deepcopy(self.mounts)
        if method == "get_subnet":
            return {"vcn_id": "vcn", "cidr_block": "10.43.0.0/17"}
        if method == "create_network_security_group":
            return {"id": "fss-nsg"}
        if method == "create_mount_target":
            self.mounts = [{"id": "mount", "lifecycle_state": "ACTIVE", "freeform_tags": {"obaas-fsdr": "test-dr"}}]
            return copy.deepcopy(self.mounts[0])
        if method == "get_mount_target":
            return copy.deepcopy(self.mounts[0])
        if method == "get_file_system":
            return {"id": args[0], "lifecycle_state": "ACTIVE", "availability_domain": region + "-ad"}
        if method == "create_file_system":
            return {"id": "ocid1.filesystem.oc1.region-1.target", "lifecycle_state": "ACTIVE"}
        if method == "list_replications":
            return copy.deepcopy(self.replications)
        if method == "create_replication":
            self.replications = [{"id": "replication", "lifecycle_state": "ACTIVE", "source_id": args[0]["sourceId"],
                                  "target_id": args[0]["targetId"], "recovery_point_time": "2026-10-07T12:00:00Z"}]
            return copy.deepcopy(self.replications[0])
        if method == "get_replication":
            return copy.deepcopy(self.replications[0])
        if method == "list_exports":
            return [{"id": "export", "path": "/data"}]
        return {}


class RecoveryTests(unittest.TestCase):
    def recovery(self, role="PRIMARY"):
        api, k8s = API(role), K8s()
        return fsdr.Preparation(copy.deepcopy(CONFIG), "region-1", api, k8s), api, k8s

    def test_cli_accepts_object_upload_headers_and_resource_data(self):
        for response, expected in (({"etag": "archive-etag"}, {"etag": "archive-etag"}),
                                   ({"data": {"items": []}}, {"items": []})):
            with self.subTest(response=response), patch.object(bootstrap, "run", return_value=SimpleNamespace(stdout=json.dumps(response))):
                self.assertEqual(bootstrap.cli("region-0", "os", "object", "put"), expected)

    def test_volume_discovery_rejects_pending_and_unsupported_pvcs(self):
        recovery, _, k8s = self.recovery()
        k8s.items[("pvc", "obaas")] = {"items": [{"metadata": {"name": "data"}, "spec": {"volumeName": "pv-1"}, "status": {"phase": "Pending"}}]}
        with self.assertRaisesRegex(RuntimeError, "bind"):
            recovery.volumes()
        k8s.items[("pvc", "obaas")]["items"][0]["status"]["phase"] = "Bound"
        k8s.items[("pv", None)] = {"items": [{"metadata": {"name": "pv-1"}, "spec": {"csi": {"driver": "unreplicated", "volumeHandle": "external"}}}]}
        with self.assertRaisesRegex(RuntimeError, "supported OCI storage"):
            recovery.volumes()
        k8s.items[("pv", None)]["items"][0]["spec"]["csi"] = {"driver": "blockvolume.csi.oraclecloud.com", "volumeHandle": "volume-1"}
        self.assertEqual(recovery.volumes(), {"block": {"volume-1"}, "file": set()})

    def test_member_merge_preserves_existing_encryption_mapping(self):
        old = {"member_id": "fs-1", "member_type": "FILE_SYSTEM", "destination_encryption_key": {"encryption_key_id": "key"}}
        merged = fsdr.merge_member([old], {"member_id": "fs-1", "export_mappings": []})
        self.assertEqual(merged[0]["destination_encryption_key"], old["destination_encryption_key"])

    def test_optional_null_member_fields_do_not_trigger_membership_changes(self):
        existing = {"member_id": "fs-1", "destination_encryption_key": None, "export_mappings": [{"export_id": "export", "destination_mount_target_id": None}]}
        desired = {"member_id": "fs-1", "export_mappings": [{"export_id": "export"}]}
        self.assertEqual(fsdr.camel_payload(existing), fsdr.camel_payload(desired))

    def test_storage_preparation_is_idempotent_and_keeps_existing_members(self):
        api, k8s = StorageAPI(), K8s()
        recovery = fsdr.Preparation(copy.deepcopy(CONFIG), "region-0", api, k8s)
        api.volumes = {"volume-1": {"availability_domain": "region-0-ad"}, "volume-2": {"availability_domain": "region-0-ad"}}
        first = recovery.block_members({"volume-1"})
        second = recovery.block_members({"volume-1"})
        self.assertEqual(first, second)
        self.assertEqual(sum(call[2] == "create_volume_group" for call in api.calls), 1)
        recovery.block_members({"volume-1", "volume-2"})
        self.assertEqual(set(api.volume_groups[0]["volume_ids"]), {"volume-1", "volume-2"})
        self.assertEqual(sum(call[2] == "create_volume_group" for call in api.calls), 1)
        self.assertTrue(any(call[0] == "region-1" and call[2] == "get_volume_group_replica" for call in api.calls))

    def test_failback_reuses_the_recovered_volume_group(self):
        api, k8s = StorageAPI(), K8s()
        api.volume_groups = [{"id": "recovered-group", "lifecycle_state": "AVAILABLE", "availability_domain": "region-1-ad",
                              "volume_ids": ["recovered-volume", "other-existing-volume"], "freeform_tags": {}, "volume_group_replicas": []}]
        recovery = fsdr.Preparation(copy.deepcopy(CONFIG), "region-1", api, k8s)
        members = recovery.block_members({"recovered-volume"})
        self.assertEqual(members[0]["member_id"], "recovered-group")
        self.assertFalse(any(call[2] == "create_volume_group" for call in api.calls))
        self.assertEqual(api.volume_groups[0]["volume_ids"], ["recovered-volume", "other-existing-volume"])
        self.assertEqual(api.volume_groups[0]["volume_group_replicas"][0]["availability_domain"], "region-0-ad")

    def test_filesystem_replication_and_export_mapping_are_idempotent(self):
        api = FileAPI()
        recovery = fsdr.Preparation(copy.deepcopy(CONFIG), "region-0", api, K8s())
        first = recovery.file_members({"ocid1.filesystem.oc1.region-0.source"})
        second = recovery.file_members({"ocid1.filesystem.oc1.region-0.source"})
        self.assertEqual(first, second)
        self.assertEqual(first[0]["export_mappings"], [{"export_id": "export", "destination_mount_target_id": "mount"}])
        self.assertEqual(sum(call[2] == "create_replication" for call in api.calls), 1)
        self.assertEqual(sum(call[2] == "create_mount_target" for call in api.calls), 1)
        target = next(call for call in api.calls if call[2] == "create_file_system")
        self.assertEqual(target[0], "region-1")
        rules = next(call for call in api.calls if call[2] == "add_network_security_group_security_rules")[3][1]["securityRules"]
        self.assertEqual(len(rules), 4)
        self.assertTrue(all(item["source"] == "10.43.0.0/17" for item in rules))

    def test_initial_enrollment_adds_database_and_oke_without_creating_plans(self):
        api, k8s = API(), K8s()
        api.groups["region-0"] = {"role": "PRIMARY", "members": []}
        recovery = fsdr.Preparation(copy.deepcopy(CONFIG), "region-0", api, k8s)
        recovery.prepare(enroll=True)
        update = next(call for call in api.calls if call[2] == "update_dr_protection_group")
        self.assertEqual({item["memberType"] for item in update[3][0]["members"]}, {"AUTONOMOUS_DATABASE", "OKE_CLUSTER"})
        self.assertFalse(any(call[2] == "create_dr_plan" for call in api.calls))
        oke = next(item for item in update[3][0]["members"] if item["memberType"] == "OKE_CLUSTER")
        self.assertEqual(oke["peerClusterId"], "region-1-oke")
        self.assertEqual(oke["backupConfig"]["replicateImages"], "ENABLE")

    def test_repeated_plan_configuration_preserves_builtins(self):
        recovery, api, _ = self.recovery()
        recovery.configure_plans("group-1")
        self.assertEqual(sum(call[2] == "refresh_dr_plan" for call in api.calls), len(CONFIG["plan_types"]))
        self.assertEqual(sum(call[2] == "verify_dr_plan" for call in api.calls), len(CONFIG["plan_types"]))
        self.assertFalse(any(call[2] == "update_dr_plan" for call in api.calls))
        plan = copy.deepcopy(api.plans[0])
        plan["plan_groups"].append({"id": "custom-id", "type": "USER_DEFINED", "display_name": "OBaaS application recovery", "steps": []})
        self.assertEqual(fsdr.native_plan_groups(plan), api.plans[0]["plan_groups"])

    def test_active_execution_stops_preparation(self):
        recovery, api, _ = self.recovery()
        api.groups["region-1"] = {"role": "PRIMARY", "members": []}
        original = api.call
        def executing(region, service, method, *args, **kwargs):
            return [{"lifecycle_state": "IN_PROGRESS"}] if method == "list_dr_plan_executions" else original(region, service, method, *args, **kwargs)
        api.call = executing
        with self.assertRaisesRegex(RuntimeError, "active recovery"):
            recovery.prepare()

    def test_active_execution_stops_bootstrap(self):
        for active_region in CONFIG["groups"]:
            with self.subTest(region=active_region):
                def cli(region, *args):
                    if args[:3] == ("disaster-recovery", "dr-plan-execution", "list"):
                        return {"items": [{"lifecycle-state": "IN_PROGRESS"}] if region == active_region else []}
                    self.fail("Active recovery must stop before cluster changes")
                with patch.object(bootstrap, "cli", side_effect=cli):
                    with self.assertRaisesRegex(RuntimeError, "active recovery execution"):
                        bootstrap.bootstrap(CONFIG)


if __name__ == "__main__":
    unittest.main()
