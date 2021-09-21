#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


if ! test "$BYO_OKE_OCID" =~ ^ocid1\.cluster; then
  cd $MY_STATE/terraform
  export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
  export TF_VAR_ociRegionIdentifier="$REGION"
  export TF_VAR_ociTenancyOcid="$TENANCY_OCID"
  export TF_VAR_vcnOcid="$VCN_OCID"

  if ! terraform init; then
      echo 'ERROR: terraform init failed!'
      exit
  fi

  if ! terraform destroy -auto-approve; then
      echo 'ERROR: terraform destroy failed!'
      exit
  fi
fi


rm -f $STATE_FILE