#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Terraform Destroy
echo "Running terraform destroy"

cd "$LAB_HOME"/cloud-setup/terraform_atp

### Terraform variables setup
### Authentication details
export TF_VAR_tenancy_ocid="$(state_get TENANCY_OCID)"
export TF_VAR_user_ocid="$(state_get USER_OCID)"

### Region
## <region in which to operate, example: us-ashburn-1, us-phoenix-1>
export TF_VAR_region="$(state_get REGION)"

### Compartment
export TF_VAR_compartment_ocid="$(state_get COMPARTMENT_OCID)"

### Database details
export TF_VAR_autonomous_database_display_name="$(state_get LAB_DB_NAME)_ATP"
export TF_VAR_autonomous_database_db_name="$(state_get LAB_DB_NAME)"

export TF_VAR_runName="$(state_get RUN_NAME)"


if ! terraform init; then
  echo 'ERROR: terraform init failed!'
  exit
fi

if ! terraform destroy -auto-approve; then
  echo 'ERROR: terraform destroy failed!'
  exit
fi

cd "$LAB_HOME"




