#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Provision Cluster, DBs, etc with terraform (and wait)
if ! state_done PROVISIONING; then
  cd $GRABDISH_HOME/terraform
  export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
  export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
  export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
  export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
  export TF_VAR_runName="$(state_get RUN_NAME)"
  export TF_VAR_orderDbName="$(state_get ORDER_DB_NAME)"
  export TF_VAR_inventoryDbName="$(state_get INVENTORY_DB_NAME)"

  if state_done K8S_PROVISIONING; then
    rm -f containerengine.tf core.tf 
  fi

  cat >~/.terraformrc <<!
provider_installation {
  filesystem_mirror {
    path    = "/usr/share/terraform/plugins"
  }
  direct {
  }
}
!

  if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit
  fi

  if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit
  fi
  
  cd $GRABDISH_HOME
  state_set_done K8S_PROVISIONING
  state_set_done PROVISIONING
fi


