#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Provision Cluster, DBs, etc with terraform (and wait)
if ! state_done PROVISIONING_DONE; then
  cd $GRABDISH_HOME/terraform
  export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
  export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
  export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
  export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
  export TF_VAR_runName="$(state_get RUN_NAME)"
  #export TF_VAR_resUserPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDELqTJTX8DHJXY3y4CiQwwJdf12fjM4MAaWRj4vRmc8A5/Jb/KABig7zz59kjhGXsspOWjIuufXMTFsO1+/MkFYp3tzNtmgyX+McuF18V8SS1TjwuRovAJcgEI4JMBWBLkI7v1G97omGDxBL0HCdkd1xQj8eqJqO96lFvGZd91T1UX0+nccFs0Fp2IyWgibzzc2hT8K8yyBIDsHMJ/Z8NE309Me+b+JkLeTL+WyUA45xIsCb+mphJKMM9ihPVRjKWsnBw2ylpnhYPTr67f7/i525cGwHDKOap7GvfaNuj7nB7efyoBCuybjyHeXxGd1kvMC5HSo6MYTPGWjoQRk+9n rexley@rexley-mac"
  #export TF_VAR_resId="$(state_get RUN_NAME)"
  if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit
  fi
  if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit
  fi
  cd $GRABDISH_HOME
  state_set_done PROVISIONING_DONE
fi


