#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Source the state functions
source utils/state_functions.sh "state"


# Identify Run Type
# Hopefully can identify shared loaned Oracle tenancy(ies)
# Ask user whether they want OCI Service or Compute based workshop
while ! state_done "RUN_TYPE"; do
  PS3='Please choose how you would like to provision resources to run this workshop: '
  options=("OCI Services" "Green Button" "On Prem")
  select opt in "${options[@]}"
  do
    case $opt in
      "OCI Services")
        state_set "RUN_TYPE" "1"
        ;;
      "Green Button")
        state_set "RUN_TYPE" "2"
        ;;
      "On Prem")
        state_set "RUN_TYPE" "3"
        ;;
      *) echo "invalid option";;
    esac
done
done


# Get the User OCID
while ! state_done "USER_OCID"; do
  read -p "Please enter your OCI user's OCID: " USER_OCID
  # Validate
  if test `oci iam user get --user-id "$USER_OCID" --query 'data."lifecycle-state"' --raw-output` == 'ACTIVE'; then
    state_set "USER_OCID" "$USER_OCID"
  else
    echo "That user could not be validated"
  fi
done


# Get the tenancy OCID
while ! state_done "TENANCY_OCID"; do
  state_set "TENANCY_OCID" "$OCI_TENANCY" # Set in cloud shell env
done


# Double check the region TODO
while ! state_done "REGION"; do
  state_set "REGION" "$OCI_REGION" # Set in cloud shell env
done


# Create the compartment
while ! state_done "COMPARTMENT_OCID"; do
  if COMPARTMENT_OCID=`oci iam compartment create --compartment-id "$(state_get TENANCY_OCID)" --name "$(state_get RUN_NAME)" --description "GribDish Workshop" --query 'data.id' --raw-output`; then
    state_set "COMPARTMENT_OCID" "$COMPARTMENT_OCID"
  else
    echo "ERROR creating compartment named $(state_get RUN_NAME)"
    exit
  fi
done

# Run the build-all.sh in the background (no push)
$GRABDISH_HOME/utils/build-all.sh &2>&1 >>$GRABDISH_HOME/logs/build-all.log &


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
source oci_cli_cs_key_auth.sh


# Provision Cluster, DBs, etc with terraform (and wait)
if ! state_done "PROVISIONING_DONE"; then
  cd $GRABDISH_HOME/terraform
  export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
  export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
  export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
  export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
  //export TF_VAR_resUserPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDELqTJTX8DHJXY3y4CiQwwJdf12fjM4MAaWRj4vRmc8A5/Jb/KABig7zz59kjhGXsspOWjIuufXMTFsO1+/MkFYp3tzNtmgyX+McuF18V8SS1TjwuRovAJcgEI4JMBWBLkI7v1G97omGDxBL0HCdkd1xQj8eqJqO96lFvGZd91T1UX0+nccFs0Fp2IyWgibzzc2hT8K8yyBIDsHMJ/Z8NE309Me+b+JkLeTL+WyUA45xIsCb+mphJKMM9ihPVRjKWsnBw2ylpnhYPTr67f7/i525cGwHDKOap7GvfaNuj7nB7efyoBCuybjyHeXxGd1kvMC5HSo6MYTPGWjoQRk+9n rexley@rexley-mac"
  //export TF_VAR_resId="$(state_get RUN_NAME)"
  if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit
  fi
  if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit
  fi
  cd $GRABDISH_HOME
  state_set_done "PROVISIONING_DONE"
fi


# Get OKE OCID
while ! state_done "OKE_OCID"; do
  OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[?name=='msdataworkshopcluster'].id)" --raw-output`
  state_set "OKE_OCID", "$OKE_OCID"
done

exists
# Get Order DB OCID
while ! state_done "ORDER_DB_OCID"; do
  ORDER_DB_OCID=`exit`
  state_set "ORDER_DB_OCID", "$ORDER_DB_OCID"
done


# Get Inventory DB OCID
while ! state_done "INVENTORY_DB_OCID"; do
  INVENTORY_DB_OCID=`exit`
  state_set "INVENTORY_DB_OCID", "$INVENTORY_DB_OCID"
done


# Get Object Store OCID
while ! state_done "OBJECT_STORE_OCID"; do
  OBJECT_STORE_OCID=`exit`
  state_set "OBJECT_STORE_OCID", "$OBJECT_STORE_OCID"
done


# Get Vault OCID
while ! state_done "VAULT_OCID"; do
  VAULT_OCID=`exit`
  state_set "VAULT_OCID", "$VAULT_OCID"
done


# run oke-setup.sh in background
$GRABDISH_HOME/utils/oke-setup.sh &2>&1 >>$GRABDISH_HOME/logs/oke-setup.log &


# run db-setup.sh in background
$GRABDISH_HOME/utils/db-setup.sh &2>&1 >>$GRABDISH_HOME/logs/db-setup.log &


# Ask user to create auth key and then prompt for key

# login to docker
DOCKER_LOGIN_DONE


# Collect DB password and create secret
DB_PASSWORD_DONE

# Set admin password in inventory database
INVENTORY_DB_PASSWORD_SET

# Set admin password in order database
ORDER_DB_PASSWORD_SET

# Collect UI password and create secret
UI_PASSWORD_DONE

# Wait for backgrounds
wait

# Verify Setup

SETUP_VERIFIED