#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


if ! test -f $MY_STATE/state_rsa_key; then
  mkdir -p $MY_STATE/ssh
  ssh-keygen -t rsa -N "" -b 2048 -C "db" -f $MY_STATE/ssh/db
  DB_PUBLIC_RSA_KEY_FILE="$MY_STATE/ssh/db.pub"
  echo "DB_PUBLIC_RSA_KEY_FILE='$DB_PUBLIC_RSA_KEY_FILE'" >>$STATE_FILE
  touch $MY_STATE/state_rsa_key
fi


if ! test -f $MY_STATE/state_provisioning_done; then
  if [[ ]]"$BYO_DB_OCID" =~ ^ocid1\.autonomousdatabase ]]; then
    # ATP DB has been provisioned already
    DB_OCID=$BYO_DB_OCID
  else
    # Execute terraform
    cp -rf $MY_CODE/terraform $MY_STATE
    cd $MY_STATE/terraform
    export TF_VAR_ociTenancyOcid="$TENANCY_OCID"
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

    if ! terraform apply -auto-approve; then
        echo 'ERROR: terraform apply failed!'
        exit 1
    fi

    # Get the DB_OCID
    DB_OCID=`terraform output -raw db_ocid`
  fi
  echo "DB_OCID='$DB_OCID'" >>$STATE_FILE
  touch $MY_STATE/state_provisioning_done
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

  cat - >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!

  DB_ALIAS=${DB_NAME}_tp
  echo "DB_ALIAS='$DB_ALIAS'" >>$STATE_FILE
  echo "TNS_ADMIN='$TNS_ADMIN'" >>$STATE_FILE
  touch $MY_STATE/state_wallet_downloaded
fi


cat >$OUTPUT_FILE <<!
DB_OCID='$DB_OCID'
DB_ALIAS='$DB_ALIAS'
TNS_ADMIN='$TNS_ADMIN'
!
