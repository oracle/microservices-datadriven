#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Remove Authenticated Link to Wallet
if test -f $MY_STATE/state_cwallet_auth_url; then
  PARIDS=`oci os preauth-request list --bucket-name "$BUCKET_NAME" --query "join(' ',data[*].id)" --raw-output`
  for id in $PARIDS; do
      oci os preauth-request delete --par-id "$id" --bucket-name "$BUCKET_NAME" --force
  done
  rm $MY_STATE/state_cwallet_auth_url
fi


# Remove Object from Bucket
if test -f $MY_STATE/state_cwallet_put; then
  oci os object delete --object-name "cwallet.sso" --bucket-name "$BUCKET_NAME" --force
  rm $MY_STATE/state_cwallet_put
fi


# Remove Bucket
if test -f $MY_STATE/state_os_bucket_created; then
   oci os bucket delete --force --bucket-name "$BUCKET_NAME" --force
 rm $MY_STATE/state_os_bucket_created
fi


# Remove wallet and other TNS information
if test -f $MY_STATE/state_wallet_downloaded; then
  TNS_ADMIN=$MY_STATE/tns_admin
  rm -rf $TNS_ADMIN
  rm $MY_STATE/state_wallet_downloaded
fi


# Cancel Set DB Password
if test -f $MY_STATE/state_password_set; then
  rm $MY_STATE/state_password_set
fi


# Execute terraform destroy
if test -f $MY_STATE/state_provisioning_done; then
  if ! test "$BYO_DB_OCID" =~ ^ocid1\.autonomousdatabase; then
    cd $MY_STATE/terraform
    export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
    export TF_VAR_ociRegionIdentifier="$REGION"
    export TF_VAR_dbName="$DB_NAME"
    export TF_VAR_displayName="$DISPLAY_NAME"
    export TF_VAR_publicRsaKey="$(<$DB_PUBLIC_RSA_KEY_FILE)"
    export TF_VAR_vcnOcid="$VCN_OCID"

    if ! terraform init; then
        echo 'ERROR: terraform init failed!'
        exit 1
    fi

    if ! terraform destroy -auto-approve; then
        echo 'ERROR: terraform destroy failed!'
        exit 1
    fi
  fi
  rm $MY_STATE/state_provisioning_done
fi


rm -f $STATE_FILE