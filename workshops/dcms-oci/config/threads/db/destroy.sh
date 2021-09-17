#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Wait for dependencies to be undone
DEPENDENCIES='GRABDISH_THREAD'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES to be undone"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  sleep 1
done


# Destroy Order and Inventory DBs
DBS="order_db inventory_db"
for db in $DBS; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  DB_STATE=$DCMS_INFRA_STATE/db/$db
  cd $DB_STATE
  provisioning-destroy
  state_reset ${db_upper}_OCID
  state_reset ${db_upper}_TNS_ADMIN
  state_reset ${db_upper}_ALIAS
  state_reset ${db_upper}_CWALLET_SSO_AUTH_URL
  state_reset ${DB_upper}_BYO_DB_OCID
done


# Delete state file
rm -f $STATE_FILE
state_reset DB_THREAD