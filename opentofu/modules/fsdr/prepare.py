# Copyright (c) 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

"""Disassociate an existing FSDR pair before Terraform deletes its groups."""

import json
import math
import os
import re
import shutil
import subprocess
import sys
import time


def cli_environment(credentials):
    environment = os.environ.copy()
    environment.pop("FSDR_OCI_CREDENTIALS", None)
    for field, provider_name, cli_name in (
        ("tenancy_ocid", "OCI_TENANCY_OCID", "OCI_CLI_TENANCY"),
        ("user_ocid", "OCI_USER_OCID", "OCI_CLI_USER"),
        ("fingerprint", "OCI_FINGERPRINT", "OCI_CLI_FINGERPRINT"),
        ("private_key_path", "OCI_PRIVATE_KEY_PATH", "OCI_CLI_KEY_FILE"),
        ("private_key", "OCI_PRIVATE_KEY", "OCI_CLI_KEY_CONTENT"),
    ):
        environment.pop(cli_name, None)
        value = credentials.get(field) or environment.get(provider_name)
        if value:
            environment[cli_name] = value
    environment["OCI_CLI_PROFILE"] = environment.get("OCI_CONFIG_FILE_PROFILE", "DEFAULT")
    auth = environment.get("OCI_AUTH")
    if not auth:
        auth = "ResourcePrincipal" if environment.get("OCI_RESOURCE_PRINCIPAL_VERSION") else "APIKey"
    environment["OCI_CLI_AUTH"] = {
        "APIKey": "api_key",
        "InstancePrincipal": "instance_principal",
        "ResourcePrincipal": "resource_principal",
        "SecurityToken": "security_token",
        "OKEWorkloadIdentity": "oke_workload_identity",
    }[auth]
    return environment


def timeout_seconds(value):
    parts = re.findall(r"(\d+(?:\.\d+)?)(h|m|s)", value)
    if not parts or "".join(number + unit for number, unit in parts) != value:
        raise ValueError("FSDR update timeout must use hours, minutes or seconds.")
    seconds = sum(float(number) * {"h": 3600, "m": 60, "s": 1}[unit] for number, unit in parts)
    if seconds <= 0:
        raise ValueError("FSDR update timeout must be positive.")
    return seconds


def prepare(configuration, credentials):
    executable = shutil.which("oci")
    if executable is None:
        raise RuntimeError("FSDR destroy preparation requires the OCI CLI on the Terraform runner.")
    groups = configuration["groups"]
    if len(groups) != 2 or len(set(groups.values())) != 2 or not all(groups.values()):
        raise ValueError("FSDR destroy preparation requires two existing regional protection groups.")
    environment = cli_environment(credentials)
    deadline = time.monotonic() + timeout_seconds(configuration["timeout"])

    def remaining():
        seconds = deadline - time.monotonic()
        if seconds <= 0:
            raise TimeoutError("Timed out waiting for both FSDR protection groups to be disassociated.")
        return seconds

    def command(region, operation, group_id, *arguments):
        result = subprocess.run(
            [executable, "--region", region, "--output", "json", "disaster-recovery",
             "dr-protection-group", operation, "--dr-protection-group-id", group_id, *arguments],
            env=environment,
            capture_output=True,
            text=True,
            timeout=remaining(),
            check=False,
        )
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or f"OCI FSDR {operation} failed in {region}.")
        return json.loads(result.stdout)["data"]

    live_groups = {region: command(region, "get", group_id) for region, group_id in groups.items()}
    for region, group in live_groups.items():
        if group["role"] == "UNCONFIGURED":
            continue
        if group["role"] not in ("PRIMARY", "STANDBY"):
            raise RuntimeError(f"Unexpected FSDR protection-group role in {region}: {group['role']}.")
        if groups.get(group.get("peer-region")) != group.get("peer-id"):
            raise RuntimeError(f"FSDR protection group in {region} has an unexpected peer.")
        response = command(
            region, "disassociate", groups[region], "--type", "DEFAULT",
            "--wait-for-state", "SUCCEEDED", "--wait-for-state", "FAILED",
            "--wait-for-state", "CANCELED", "--max-wait-seconds", str(math.ceil(remaining())),
        )
        if response["status"] != "SUCCEEDED":
            raise RuntimeError(f"FSDR disassociation work request ended with {response['status']}.")
        live_groups = {region: command(region, "get", group_id) for region, group_id in groups.items()}
        break

    while not all(group["role"] == "UNCONFIGURED" for group in live_groups.values()):
        time.sleep(min(5, remaining()))
        live_groups = {region: command(region, "get", group_id) for region, group_id in groups.items()}
    print("Both FSDR protection groups are disassociated.")


if __name__ == "__main__":
    try:
        prepare(json.loads(os.environ["FSDR_PREPARATION"]), json.loads(os.environ["FSDR_OCI_CREDENTIALS"]))
    except (KeyError, ValueError, OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"FSDR destroy preparation failed: {error}", file=sys.stderr)
        raise SystemExit(1) from None
