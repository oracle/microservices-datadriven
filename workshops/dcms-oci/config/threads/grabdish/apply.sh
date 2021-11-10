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
DB_DEPLOYMENT="$(state_get DB_DEPLOYMENT)"
DB_TYPE="$(state_get DB_TYPE)"
QUEUE_TYPE="$(state_get QUEUE_TYPE)"
DB_PASSWORD_SECRET=$(state_get DB_PASSWORD_SECRET)
UI_PASSWORD_SECRET=$(state_get UI_PASSWORD_SECRET)
DB1_TNS_ADMIN=$(state_get DB1_TNS_ADMIN)
DB1_DB_ALIAS=$(state_get DB1_DB_ALIAS)
DB2_DB_TNS_ADMIN=$(state_get DB2_DB_TNS_ADMIN)
DB2_DB_ALIAS=$(state_get DB2_DB_ALIAS)
GRABDISH_LOG=$DCMS_LOG_DIR
!
cd $STATE
provisioning-apply $MSDD_APPS_CODE/$DCMS_APP/config


touch $OUTPUT_FILE
state_set_done GRABDISH_THREAD