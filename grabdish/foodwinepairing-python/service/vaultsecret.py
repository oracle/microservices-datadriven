# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/This software is dual-licensed to you under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.

import oci
import sys
from datetime import datetime
from datetime import timedelta

def get_secret(vaults_client, secret_id):
    return vaults_client.get_secret(secret_id)


if len(sys.argv) != 3:
    raise RuntimeError(
        'This example expects an ocid for the secret to read.')

compartment_id = sys.argv[1]
oci_profile = sys.argv[2]

config = config = oci.config.from_file(
    "~/.oci/config",
    oci_profile)

secret_content = "TestContent"
secret_name = "TestSecret"
VAULT_NAME = "KmsVault"
KEY_NAME = "KmsKey"

# Vault client to create vault
kms_vault_client = oci.key_management.KmsVaultClient(config)
kms_vault_client_composite = oci.key_management.KmsVaultClientCompositeOperations(
    kms_vault_client)

# This will create a vault in the given compartment
vault = create_vault(compartment_id, VAULT_NAME, kms_vault_client_composite).data
# vault = get_vault(kms_vault_client, vault_id).data
vault_id = vault.id
print(" Created vault {} with id : {}".format(VAULT_NAME, vault_id))

# Vault Management client to create a key
vault_management_client = oci.key_management.KmsManagementClient(config,
                                                                 service_endpoint=vault.management_endpoint)
vault_management_client_composite = oci.key_management.KmsManagementClientCompositeOperations(
    vault_management_client)

# Create key in given compartment
key = create_key(vault_management_client_composite, KEY_NAME, compartment_id).data
# key = get_key(vault_management_client,key_id).data
key_id = key.id
print(" Created key {} with id : {}".format(KEY_NAME, key.id))

# Vault client to manage secrets
vaults_client = oci.vault.VaultsClient(config)
vaults_management_client_composite = oci.vault.VaultsClientCompositeOperations(vaults_client)

secret = create_secret(vaults_management_client_composite, compartment_id, secret_content, secret_name, vault_id, key_id).data
secret_id = secret.id
print("Secret ID is {}.".format(secret_id))

secret_deletion_time = datetime.now() + timedelta(days=2)
delete_secret(vaults_client, secret_id, secret_deletion_time)