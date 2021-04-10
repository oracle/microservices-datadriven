#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
source $GRABDISH_HOME/utils/oci-cli-cs-key-auth.sh

# Delete Object Store
echo "Deleting Object Store"
# Per-auth
if state_done WALLET_AUTH_URL; then
  PARIDS=`oci os preauth-request list --bucket-name "$(state_get RUN_NAME)" --query "join(' ',data[*].id)" --raw-output`
  for id in $PARIDS; do
    oci os preauth-request delete --par-id "$id" --bucket-name "$(state_get RUN_NAME)" --force
  done
  state_reset WALLET_AUTH_URL
fi

# Object
if state_done WALLET_OBJECT_DONE; then
  oci os object delete --object-name "wallet" --bucket-name "$(state_get RUN_NAME)" --force
  state_reset WALLET_OBJECT_DONE
fi
# Bucket
if state_done OBJECT_STORE_BUCKET; then
   oci os bucket delete --force --bucket-name "$(state_get RUN_NAME)" --force
 state_reset OBJECT_STORE_BUCKET
fi

# Delete Vault

# Delete Images
echo "Deleting Images"
IIDS=`oci artifacts container image list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data.items[*].id)" --raw-output`
for i in $IIDS; do
  oci artifacts container image delete --image-id "$i" --force
done

# Delete Repos
echo "Deleting Repositories"
REPO_IDS=`oci artifacts container repository list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ', data.items[*].id)" --raw-output`
for r in $REPO_IDS; do 
  oci artifacts container repository delete --repository-id "$r" --force
done

# Delete LBs
echo "Deleting Load Balancers"
LBIDS=`oci lb load-balancer list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[*].id)" --raw-output`
for lb in $LBIDS; do
  oci lb load-balancer delete --load-balancer-id "$lb" --force
done

# Terraform Destroy
echo "Running terraform destroy"
cd $GRABDISH_HOME/terraform
export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
export TF_VAR_runName="$(state_get RUN_NAME)"
terraform destroy -auto-approve

# Delete Compartment
# oci iam compartment delete --compartment-id "$(state_get COMPARTMENT_OCID)"