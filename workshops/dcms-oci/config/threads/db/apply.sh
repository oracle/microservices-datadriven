#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


if state_done DB_THREAD; then
  exit
fi


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID REGION ORDER_DB_NAME INVENTORY_DB_NAME DB_PASSWORD_SECRET RUN_NAME ATP_LIMIT_CHECK'
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


# Provision Order and Inventory DB
DBS="order_db inventory_db"
for db in $DBS; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  DB_STATE=$DCMS_INFRA_STATE/db/$db
  mkdir -p $DB_STATE
  cat >$DB_STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
REGION=$(state_get REGION)
DB_NAME=$(state_get ${db_upper}_NAME)
DISPLAY_NAME=${db_upper}
DB_PASSWORD_SECRET=$(state_get DB_PASSWORD_SECRET)
RUN_NAME=$(state_get RUN_NAME)
!
  cd $DB_STATE
  provisioning-apply $MSDD_INFRA_CODE/db/atp

  (
  source $DB_STATE/output.env
  state_set ${db_upper}_OCID "$DB_OCID"
  state_set ${db_upper}_TNS_ADMIN $TNS_ADMIN
  state_set ${db_upper}_ALIAS "$DB_ALIAS"
  state_set ${db_upper}_CWALLET_SSO_AUTH_URL "$CWALLET_SSO_AUTH_URL"
  )
done

touch $OUTPUT_FILE
state_set_done DB_THREAD