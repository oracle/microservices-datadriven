#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Workaround for cloud shell bug where it caches only on terraform version
  cat >~/.terraformrc <<!
provider_installation {
  filesystem_mirror {
    path    = "/usr/share/terraform/plugins"
  }
  direct {
  }
}
!


# Execute terraform
cp -rf $MY_CODE/terraform $MY_STATE

cd $MY_STATE/terraform
export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
export TF_VAR_ociRegionIdentifier="$REGION"
export TF_VAR_vcnDnsLabel="$VCN_DNS_LABEL"

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi

# Get the VCN_OCID
VCN_OCID=`terraform output -raw vcn_ocid`
echo "VCN_OCID='$VCN_OCID'" >>$STATE_FILE

cat >$OUTPUT_FILE <<!
VCN_OCID='$VCN_OCID'
!