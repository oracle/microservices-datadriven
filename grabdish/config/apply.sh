#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


cd $MY_CODE/..
export GRABDISH_HOME=$PWD


# Run grabdish apply for each config in order
CONFIGS="db k8s db-k8s"
for c in $CONFIGS; do
  CONFIG_CODE=$MY_CODE/$c
  CONFIG_STATE=$MY_STATE/$c
  mkdir -p $CONFIG_STATE
  cat >$CONFIG_STATE/input.env <<!
DB_PASSWORD_SECRET=$DB_PASSWORD_SECRET
UI_PASSWORD_SECRET=$UI_PASSWORD_SECRET
ORDERDB_TNS_ADMIN=$ORDERDB_TNS_ADMIN
ORDERDB_ALIAS=$ORDERDB_ALIAS
INVENTORYDB_TNS_ADMIN=$INVENTORYDB_TNS_ADMIN
INVENTORYDB_ALIAS=$INVENTORYDB_ALIAS
ORDERDB_CWALLET_SSO_AUTH_URL='$ORDERDB_CWALLET_SSO_AUTH_URL'
GRABDISH_LOG=$GRABDISH_LOG
!
  cd $CONFIG_STATE
  provisioning-apply $CONFIG_CODE
done


touch $OUTPUT_FILE