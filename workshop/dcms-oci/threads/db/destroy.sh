#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Check the code home is set
if test -z "$MSDD_CODE_HOME"; then
  echo "ERROR: This script requires MSDD_CODE_HOME environment variable to be set"
  exit
fi


# Check the workshop home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The workshop home folder does not exist"
  exit
fi


# Check if we are already done
if state_done DB_DESTROY_THREAD; then
  exit
fi


# Prevent parallel execution
PID_FILE=$MY_HOME/PID
if test -f $PID_FILE; then
    echo "The script is already running."
    echo "If you want to restart it, kill process $(cat $PID_FILE), delete the file $PID_FILE, and then retry"
    exit
fi
trap "rm -f -- '$PID_FILE'" EXIT
echo $$ > "$PID_FILE"


# Wait for dependencies
DEPENDENCIES=''
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


# Destory Order and Inventory DB
DBS="orderdb inventorydb"
for db in $DBS; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  DB_HOME=$DCMS_INFRA_HOME/db/$db
  mkdir -p $DB_HOME
  $MSDD_CODE_HOME/infra/db/atp/destroy.sh $DB_HOME
done


state_set_done DB_DESTROY_THREAD