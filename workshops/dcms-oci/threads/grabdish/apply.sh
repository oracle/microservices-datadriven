#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


if state_done GRABDISH_THREAD; then
  exit
fi


# Wait for database and k8s threads
DEPENDENCIES='DB_THREAD K8S_THREAD'
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
STATE=$DCMS_APP_STATE/config
mkdir -p $STATE
cat >$STATE/input.env <<!
DB_PASSWORD_SECRET=$(state_get DB_PASSWORD_SECRET)
UI_PASSWORD_SECRET=$(state_get UI_PASSWORD_SECRET)
ORDERDB_TNS_ADMIN=$(state_get ORDERDB_TNS_ADMIN)
ORDERDB_ALIAS=$(state_get ORDERDB_ALIAS)
INVENTORYDB_TNS_ADMIN=$(state_get INVENTORYDB_TNS_ADMIN)
INVENTORYDB_ALIAS=$(state_get INVENTORYDB_ALIAS)
ORDERDB_CWALLET_SSO_AUTH_URL='$(state_get ORDERDB_CWALLET_SSO_AUTH_URL)'
INVENTORYDB_CWALLET_SSO_AUTH_URL='$(state_get INVENTORYDB_CWALLET_SSO_AUTH_URL)'
GRABDISH_LOG=$DCMS_LOG_DIR
!
cd $STATE
provisioning-apply $MSDD_APPS_CODE/$DCMS_APP/config


touch $OUTPUT_FILE
state_set_done GRABDISH_THREAD