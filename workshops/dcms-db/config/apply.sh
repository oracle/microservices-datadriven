#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi

QUEUE_TYPE=$(state_get QUEUE_TYPE)
OCI_REGION="$(state_get OCI_REGION)"

# Generate the ssh keys
if ! test -d $MY_STATE/ssh; then
  mkdir -p $MY_STATE/ssh
  ssh-keygen -t rsa -N "" -b 2048 -C "db" -f $MY_STATE/ssh/dcmsdb
  state_set SSH_PUBLIC_KEY_FILE $"$MY_STATE/ssh/dcmsdb.pub"
  state_set SSH_PRIVATE_KEY_FILE "$MY_STATE/ssh/dcmsdb"
fi

# Copy terraform to my state
if ! test -d $MY_STATE/terraform; then
  rm -rf $MY_STATE/terraform
  cp -r $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/terraform $MY_STATE
fi

# Start the provisioning apply
cd $MY_STATE/terraform
source terraform-env.sh

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi

# Get the load balancer public IP
state_set LB_ADDRESS `terraform output -raw lb_address`

# Get the ORDS instance public IP
state_set ORDS_ADDRESS `terraform output -raw ords_address`

# Get the ORDS instance public IP
state_set DB_OCID `terraform output -raw db_ocid`

state_set TNS_ADMIN_ZIP_FILE $MY_STATE/terraform/uploads/adb_wallet.zip
TNS_ADMIN=$MY_STATE/tns_admin
mkdir -p $TNS_ADMIN
unzip $(state_get TNS_ADMIN_ZIP_FILE) -d $TNS_ADMIN
cat >$TNS_ADMIN/sqlnet.ora <<- !
	WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
	SSL_SERVER_DN_MATCH=yes
!

state_set TNS_ADMIN $TNS_ADMIN

# Write the output
cat >$OUTPUT_FILE <<!
export LB_ADDRESS='$(state_get LB_ADDRESS)'
export ORDS_ADDRESS='$(state_get ORDS_ADDRESS)'
export TNS_ADMIN='$(state_get TNS_ADMIN)'
!
