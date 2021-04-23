#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Vault
while ! state_done VAULT_OCID; do
  # Create a vault
  VAULT_OCID=`oci kms management vault create --compartment-id $(state_get COMPARTMENT_OCID) --display-name 'grabdish' --vault-type DEFAULT --query 'data.id' --raw-output`
  while test ""`oci kms management vault get --vault-id "$VAULT_OCID" --query 'data."lifecycle-state"' --raw-output` != 'ACTIVE'; do
    sleep 2
  done
  state_set VAULT_OCID "$VAULT_OCID"
done


# Vault Key
while ! state_done VAULT_KEY_OCID; do
  # Create a vault
  while ! MGMT_ENDPOINT=`oci kms management vault get --vault-id $(state_get VAULT_OCID) --query 'data."management-endpoint"' --raw-output`; do
    echo "Waiting for vault"
    sleep 5
  done
  VAULT_KEY_OCID=`oci kms management key create --compartment-id $(state_get COMPARTMENT_OCID) --display-name "default" --key-shape '{"algorithm":"AES","length":"32"}' --endpoint "$MGMT_ENDPOINT" --query 'data.id' --raw-output`
  state_set VAULT_KEY_OCID "$VAULT_KEY_OCID"
done


# Vault Dynamic Group
while ! state_done VAULT_DG_OCID; do
  RULE="All {instance.compartment.id = '$(state_get COMPARTMENT_OCID)'}"
  DG_OCID=`oci iam dynamic-group create --name "$(state_get RUN_NAME)" --description "grabdish" --matching-rule "$RULE" --query 'data.id' --raw-output`
  state_set VAULT_DG_OCID "$DG_OCID"
done


# Vault Key
while ! state_done VAULT_POLICY_OCID; do
  POLICY='["'"Allow dynamic-group $(state_get RUN_NAME) to manage secret-family in compartment id $(state_get COMPARTMENT_OCID) where target.vault.id = '$(state_get VAULT_OCID)'"'"]'
  POLICY_OCID=`oci iam policy create --compartment-id $(state_get COMPARTMENT_OCID) --name "$(state_get RUN_NAME)" --description "grabdish" --statements "$POLICY" --query 'data.id' --raw-output`
  state_set VAULT_POLICY_OCID "$POLICY_OCID"
done

state_set_done VAULT_SETUP