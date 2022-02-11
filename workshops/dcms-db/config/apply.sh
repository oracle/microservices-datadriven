#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi

QUEUE_TYPE=$(state_get QUEUE_TYPE)
DB_PASSWORD_SECRET=$(state_get DB_PASSWORD_SECRET)
UI_PASSWORD_SECRET=$(state_get UI_PASSWORD_SECRET)
OCI_REGION="$(state_get OCI_REGION)"
DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)

# Copy terraform to my state
rm -rf $MY_STATE/terraform
cp -r $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/terraform $MY_STATE

# Source the DB environment variables
source $MY_STATE/terraform/uploads/db/params.env

# Expand the common files
cd $MY_STATE/terraform/uploads/db/common/apply
files=$(ls)
for f in $files; do
  cat $f >TEMP
  eval "
cat >$f <<!
$(<TEMP)
!
"
  rm TEMP
  chmod 400 $f
done

# Expand the 1db files
cd $MY_STATE/terraform/uploads/db/1db/apply
files=$(ls)
for f in $files; do
  cat $f >TEMP
  eval "
cat >$f <<!
$(<TEMP)
!
"
  rm TEMP
  chmod 400 $f
done

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
