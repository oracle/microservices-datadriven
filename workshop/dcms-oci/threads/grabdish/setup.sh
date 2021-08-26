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
if state_done GRABDISH_THREAD; then
  exit
fi


# Wait for database and k8s threads
DEPENDENCIES='DATABASE_THREAD K8S_THREAD'
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


# Run the grabdish app setup
export GRABDISH_HOME=$MSDD_CODE_HOME/grabdish
export GRABDISH_LOG=$DCMS_WORKSHOP_LOG
cat >$DCMS_APP_HOME/input.env <<!
COMPARTMENT_OCID='$$(state_get COMPARTMENT_OCID)'
ORDERDB_TNS_ADMIN='$(state_get ORDERDB_TNS_ADMIN)'
ORDERDB_ALIAS='$(state_get ORDERDB_ALIAS)'
INVENTORYDB_ALIAS='$(state_get INVENTORYDB_ALIAS)'
REGION='$(state_get REGION)'
RUN_NAME='$(state_get RUN_NAME)'
DOCKER_REGISTRY='$(state_get DOCKER_REGISTRY)'
!
$GRABDISH_HOME/config/setup.sh $DCMS_APP_HOME
