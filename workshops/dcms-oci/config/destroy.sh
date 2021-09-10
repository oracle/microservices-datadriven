#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


source $MY_CODE/source.env


# Source the vault
VAULT=$DCMS_INFRA_STATE/vault
if test -f $VAULT/output.env; then
  source $VAULT/output.env
fi


# Start the background destroy threads
THREADS="db build-prep k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  mkdir -p $THREAD_STATE
  cd $THREAD_STATE
  (provisioning-destroy "$MY_CODE/threads/$t" &>> $DCMS_LOG_DIR/$t-destroy-thread.log) &
done


# Wait for the threads to undo the setup
DEPENDENCIES='DB_THREAD K8S_THREAD BUILD_PREP_THREAD GRABDISH_THREAD'
while ! test -z "$DEPENDENCIES"; do
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  echo "Waiting for $DEPENDENCIES to be undone"
  sleep 5
done


# Logout of docker
if state_done DOCKER_REGISTRY; then
   docker logout "$(state_get REGION).ocir.io" 
   state_reset DOCKER_REGISTRY
fi


# Destroy the vault
VAULT=$DCMS_INFRA_STATE/vault
if test -d $VAULT; then
  cd $VAULT
  provisioning-destroy
fi


# Destroy the state store.  This unsets all the other state variables.
STATE_STORE=$DCMS_INFRA_STATE/state_store
if test -d $STATE_STORE; then
  cd $STATE_STORE
  provisioning-destroy
fi

rm -f $STATE_FILE