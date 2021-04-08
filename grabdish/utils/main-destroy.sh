#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
source $GRABDISH_HOME/utils/oci-cli-cs-key-auth.sh

# Delete Object Store
# oci os preauth-request delete --namespace 'wallet'  --bucket-name "$(state_get RUN_NAME)" --name 'grabdish'
# oci os object delete --bucket-name "$(state_get RUN_NAME)" --name "wallet"
# oci os bucket delete --force --name "$(state_get RUN_NAME)"

# Delete Vault

# Delete Repos
#REPO_IDS=`oci artifacts container repository list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ', data.items[*].id)" --raw-output`
#for b in $REPO_IDS; do 
#  oci artifacts container repository delete --repository-id "$REPO_IDS"
#done

# Terraform Destroy
cd $GRABDISH_HOME/terraform
export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
export TF_VAR_runName="$(state_get RUN_NAME)"
terraform destroy

# Delete Compartment
# oci iam compartment delete --compartment-id "$(state_get COMPARTMENT_OCID)"