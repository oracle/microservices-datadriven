#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# INPUTS:
# input.env or in environment
#
# OUTPUTS:
# output.env

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


# Prevent parallel execution
PID_FILE=$MY_HOME/PID
if test -f $PID_FILE; then
    echo "The script is already running."
    echo "If you want to restart it, kill process $(cat $PID_FILE), delete the file $PID_FILE, and then retry"
fi
trap "rm -f -- '$PID_FILE'" EXIT
echo $$ > "$PID_FILE"


# Locate my code
MY_CODE=$MSDD_CODE_HOME/workshop/dcms-oci


# Locate homes
export DCMS_INFRA_HOME=$MY_HOME/infra
export DCMS_APP_HOME=$MY_HOME/grabdish
export DCMS_THREAD_HOME=$MY_HOME/threads


# Export log folder
export DCMS_WORKSHOP_LOG=$MY_HOME/log


# Setup state store
mkdir -p $MY_HOME/infra/state_store
source $MSDD_CODE_HOME/infra/state_store/setup.env $MY_HOME/infra/state_store $DCMS_WORKSHOP_LOG/state.log


# Setup secret vault
mkdir -p $MY_HOME/infra/vault
source $MSDD_CODE_HOME/infra/vault/folder/setup.env $MY_HOME/infra/vault


# Start the destroy threads
THREADS="db builds k8s grabdish"
for t in $THREADS; do
  mkdir -p $DCMS_THREAD_HOME/$t
  SETUP_SCRIPT="$MY_CODE/threads/$t/destroy.sh"
  nohup $SETUP_SCRIPT $DCMS_THREAD_HOME/$t &>> $DCMS_WORKSHOP_LOG/$t-destroy-thread.log &
done


# Wait for the threads to complete
DEPENDENCIES='DB_DESTROY_THREAD K8S_DESTROY_THREAD BUILDS_DESTROY_THREAD GRABDISH_DESTROY_THREAD'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  echo "Waiting for $DEPENDENCIES"
  sleep 5
done


# Logout of docker
if state_done DOCKER_REGISTRY; do
   docker logout "$(state_get REGION).ocir.io" 
fi


# Delete infra, workshop and app folders
# rm -rf $MY_HOME