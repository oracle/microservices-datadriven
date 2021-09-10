#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Execute terraform
if ! test -f $MY_STATE/state_terraform_done; then
  cp -rf $MY_CODE/terraform $MY_STATE
  cd $MY_STATE/terraform
  export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
  export TF_VAR_ociRegionIdentifier="$REGION"
  export TF_VAR_dbName="$DB_NAME"
  export TF_VAR_displayName="$DISPLAY_NAME"

  if ! terraform init; then
      echo 'ERROR: terraform init failed!'
      exit 1
  fi

  if ! terraform apply -auto-approve; then
      echo 'ERROR: terraform apply failed!'
      exit 1
  fi

  # Get the DB_OCID
  DB_OCID=`terraform output -raw db_ocid`

  echo "DB_OCID='$DB_OCID'" >>$STATE_FILE
  touch $MY_STATE/state_terraform_done
fi


# Set DB Password
if ! test -f $MY_STATE/state_password_set; then
  DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  umask 22
  oci db autonomous-database update --autonomous-database-id "$DB_OCID" --from-json "file://temp_params" >/dev/null
  rm temp_params
  echo "PASSWORD_SET='DONE'" >>$STATE_FILE
  touch $MY_STATE/state_password_set
fi


# Download the wallet
if ! test -f $MY_STATE/state_wallet_downloaded; then
  TNS_ADMIN=$MY_STATE/tns_admin
  mkdir -p $TNS_ADMIN
  rm -rf $TNS_ADMIN/*
  cd $TNS_ADMIN
  echo "DB OCID is $DB_OCID"
  oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
  unzip wallet.zip

  DB_ALIAS=${DB_NAME}_tp
  echo "DB_ALIAS='$DB_ALIAS'" >>$STATE_FILE
  echo "TNS_ADMIN='$TNS_ADMIN'" >>$STATE_FILE
  touch $MY_STATE/state_wallet_downloaded
fi


# Create Object Store Bucket
if ! test -f $MY_STATE/state_os_bucket_created; then
  BUCKET_NAME="${RUN_NAME}_${DB_NAME}_cwallet"
  oci os bucket create --compartment-id "$COMPARTMENT_OCID" --name "$BUCKET_NAME"
  echo "BUCKET_NAME='$BUCKET_NAME'" >>$STATE_FILE
  touch $MY_STATE/state_os_bucket_created
fi


# Put DB Connection Wallet in the bucket in Object Store
if ! test -f $MY_STATE/state_cwallet_put; then
  cd $TNS_ADMIN
  oci os object put --bucket-name $BUCKET_NAME --name "cwallet.sso" --file 'cwallet.sso'
  touch $MY_STATE/state_cwallet_put
fi


# Create Authenticated Link to Wallet
if ! test -f $MY_STATE/state_cwallet_auth_url; then
  ACCESS_URI=`oci os preauth-request create --object-name 'cwallet.sso' --access-type 'ObjectRead' --bucket-name $BUCKET_NAME --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
  CWALLET_SSO_AUTH_URL="https://objectstorage.${REGION}.oraclecloud.com${ACCESS_URI}"
  echo "CWALLET_SSO_AUTH_URL='$CWALLET_SSO_AUTH_URL'" >>$STATE_FILE
  touch $MY_STATE/state_cwallet_auth_url
fi


cat >$OUTPUT_FILE <<!
DB_OCID='$DB_OCID'
DB_ALIAS='$DB_ALIAS'
TNS_ADMIN='$TNS_ADMIN'
CWALLET_SSO_AUTH_URL='$CWALLET_SSO_AUTH_URL'
!
