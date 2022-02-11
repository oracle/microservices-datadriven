#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi

DB_DEPLOYMENT='$(state_get DB_DEPLOYMENT)'
DB_TYPE='$(state_get DB_TYPE)'
QUEUE_TYPE='$(state_get QUEUE_TYPE)'
DB_PASSWORD_SECRET='$(state_get DB_PASSWORD_SECRET)'
UI_PASSWORD_SECRET='$(state_get UI_PASSWORD_SECRET)'
OCI_REGION='$(state_get OCI_REGION)'

DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)

GRABDISH_DB_CONFIG_CODE=$MSDD_WORKSHOP_CODE/grabdish/config/db

# Source the DB environment variables
source $GRABDISH_DB_CONFIG_CODE/params.env

# Copy terraform to my state
if ! test -d $MY_STATE/terraform; then
  cp -r $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/terraform $MY_STATE
fi

# Supplement uploads with the DB expanded common scripts
COMMON_SCRIPT_HOME=$MY_STATE/terraform/uploads/db/common
if ! test -d $COMMON_SCRIPT_HOME; then
  # Expand common scripts
  mkdir -p $COMMON_SCRIPT_HOME
  chmod 700 $COMMON_SCRIPT_HOME
  files=$(ls $GRABDISH_DB_CONFIG_CODE/common/apply)
  for f in $files; do
    eval "
  cat >$COMMON_SCRIPT_HOME/$f <<!
  $(<$GRABDISH_DB_CONFIG_CODE/common/apply/$f)
  !
  "
    chmod 400 $COMMON_SCRIPT_HOME/$f
  done
fi

# Supplement uploads with the DB expanded base scripts
COMMON_SCRIPT_HOME='../common' # Referred to in base scripts
BASE_SCRIPT_HOME=$MY_STATE/terraform/uploads/db/db1
if ! test -d $BASE_SCRIPT_HOME; then
  # Expand common scripts
  mkdir -p $BASE_SCRIPT_HOME
  chmod 700 $BASE_SCRIPT_HOME
  files=$(ls $GRABDISH_DB_CONFIG_CODE/db1/apply)
  for f in $files; do
    eval "
  cat >$BASE_SCRIPT_HOME/$f <<!
  $(<$GRABDISH_DB_CONFIG_CODE/db1/apply/$f)
  !
  "
    chmod 400 $BASE_SCRIPT_HOME/$f
  done
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

# Get the OKE_OCID
state_set LB_ADDRESS `terraform output -raw lb_address`

# Write the output
cat >$OUTPUT_FILE <<!
export LB_ADDRESS='$(state_get LB_ADDRESS)'
!
