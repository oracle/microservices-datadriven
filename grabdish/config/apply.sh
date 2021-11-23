#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
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
DB_DEPLOYMENT='$DB_DEPLOYMENT'
DB_TYPE='$DB_TYPE'
QUEUE_TYPE='$QUEUE_TYPE'
DB_PASSWORD_SECRET=$DB_PASSWORD_SECRET
UI_PASSWORD_SECRET=$UI_PASSWORD_SECRET
DB1_TNS_ADMIN=$DB1_TNS_ADMIN
DB1_ALIAS=$DB1_ALIAS
DB2_TNS_ADMIN=$DB2_TNS_ADMIN
DB2_ALIAS=$DB2_ALIAS
CWALLET_OS_BUCKET=$CWALLET_OS_BUCKET
OCI_REGION=$OCI_REGION
GRABDISH_LOG=$GRABDISH_LOG
!
  cd $CONFIG_STATE
  provisioning-apply $CONFIG_CODE
done


cat >$OUTPUT_FILE <<!
ORDER_DB_ALIAS="$DB1_ALIAS"
ORDER_DB_TNS_ADMIN="$DB1_TNS_ADMIN"
INVENTORY_DB_ALIAS="$DB2_ALIAS"
INVENTORY_DB_TNS_ADMIN="$DB2_TNS_ADMIN"
RECOMM_DB_ALIAS="$DB2_ALIAS"
RECOMM_DB_TNS_ADMIN="$DB2_TNS_ADMIN"
!