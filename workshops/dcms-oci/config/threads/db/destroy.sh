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


# Destroy the DBs
DBS="db1 db2"
for db in $DBS; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  if ! state_done ${db_upper}_OCID; then
    # Already destroyed
    continue
  fi
  if test "$(state_get RUN_TYPE)" == "LL" || test -z "$(state_get ${db_upper}_OCID)"; then
    # Nothing to destroy
    :
  else
    DB_STATE=$DCMS_INFRA_STATE/db/$db
    cd $DB_STATE
    provisioning-destroy
  fi
  state_reset ${db_upper}_OCID
  state_reset ${db_upper}_TNS_ADMIN
  state_reset ${db_upper}_ALIAS
done


# Destroy the Object Store Bucket (ATP only)
if test "$(state_get DB_TYPE)" == "ATP"; then
  OS_STATE=$DCMS_INFRA_STATE/os
  mkdir -p $OS_STATE
  cd $OS_STATE
  provisioning-destroy
  state_reset CWALLET_OS_BUCKET "$(state_get RUN_NAME)"
fi


# Delete state file
rm -f $STATE_FILE
state_reset DB_THREAD