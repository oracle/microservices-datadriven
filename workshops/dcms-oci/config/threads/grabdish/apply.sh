#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


if state_done GRABDISH_THREAD; then
  exit
fi


# Wait for database and k8s threads
DEPENDENCIES='DB_THREAD K8S_THREAD DB_DEPLOYMENT DB_TYPE'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  sleep 1
done


# Run the grabdish app apply
STATE=$DCMS_APP_STATE
mkdir -p $STATE
cat >$STATE/input.env <<!
DB_DEPLOYMENT='$(state_get DB_DEPLOYMENT)'
DB_TYPE='$(state_get DB_TYPE)'
QUEUE_TYPE='$(state_get QUEUE_TYPE)'
DB_PASSWORD_SECRET='$(state_get DB_PASSWORD_SECRET)'
UI_PASSWORD_SECRET='$(state_get UI_PASSWORD_SECRET)'
DB1_NAME='$(state_get DB1_NAME)'
DB1_TNS_ADMIN='$(state_get DB1_TNS_ADMIN)'
DB1_ALIAS='$(state_get DB1_ALIAS)'
DB2_NAME='$(state_get DB2_NAME)'
DB2_TNS_ADMIN='$(state_get DB2_TNS_ADMIN)'
DB2_ALIAS='$(state_get DB2_ALIAS)'
CWALLET_OS_BUCKET='$(state_get RUN_NAME)'
OCI_REGION='$(state_get OCI_REGION)'
GRABDISH_LOG='$DCMS_LOG_DIR'
!
cd $STATE
provisioning-apply $MSDD_APPS_CODE/$DCMS_APP/config
source $STATE/output.env

state_set ORDER_DB_NAME "$ORDER_DB_NAME"
state_set ORDER_DB_ALIAS "$ORDER_DB_ALIAS"
state_set ORDER_DB_TNS_ADMIN "$ORDER_DB_TNS_ADMIN"
state_set INVENTORY_DB_NAME "$INVENTORY_DB_NAME"
state_set INVENTORY_DB_ALIAS "$INVENTORY_DB_ALIAS"
state_set INVENTORY_DB_TNS_ADMIN "$INVENTORY_DB_TNS_ADMIN"

touch $OUTPUT_FILE
state_set_done GRABDISH_THREAD