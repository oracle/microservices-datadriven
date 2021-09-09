#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy-sh; then
  exit 1
fi


export DCMS_STATE=$MY_STATE
source $MY_CODE/source.env


# Setup state store - I know we are in destroy, but we need the state store to know how to coordinate.
cd $MY_STATE/infra/state_store
provisioning-apply || true


# Start the background destroy threads
THREADS="db builds k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  mkdir -p $THREAD_STATE
  cd $THREAD_STATE
  (provisioning-destroy "$MY_CODE/threads/$t" &>> $DCMS_LOG_DIR/$t-destroy-thread.log) &
done


# Wait for the threads to undo the setup
DEPENDENCIES='DB_THREAD K8S_THREAD BUILDS_THREAD GRABDISH_THREAD'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES to be undone"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  echo "Waiting for $DEPENDENCIES"
  sleep 5
done


# Logout of docker
if state_done DOCKER_REGISTRY; then
   docker logout "$(state_get REGION).ocir.io" 
fi


# Unset all the other state variable TBD