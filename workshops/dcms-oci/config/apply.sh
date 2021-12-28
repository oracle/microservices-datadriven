#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi

# Make sure folders are created
export DCMS_INFRA_STATE=$DCMS_STATE/infra
export DCMS_APP_STATE=$DCMS_STATE/grabdish
export DCMS_THREAD_STATE=$DCMS_STATE/threads
mkdir -p $DCMS_INFRA_STATE $DCMS_APP_STATE $DCMS_THREAD_STATE 

# Start the background threads
THREADS="db build-prep k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  mkdir -p $THREAD_STATE
  cd $THREAD_STATE
  THREAD_CODE="$MY_CODE/threads/$t"
  nohup bash -c "provisioning-apply $THREAD_CODE" >>$DCMS_LOG_DIR/$t-thread.log 2>&1 &
done

# Check the threads
while true; do
  sleep 10
  RUNNING_THREADS=''
  for t in $THREADS; do
    THREAD_STATE=$DCMS_THREAD_STATE/$t
    STATUS=$(provisioning-get-status $THREAD_STATE)
    case "$STATUS" in
      applied | byo)
        # Nothing to do
        ;;

      applying)
        RUNNING_THREADS="$RUNNING_THREADS $t"
        ;;

      applying-failed)
        # Thread failed so exit
        echo "ERROR: Thread $t failed"
        exit 1
        ;;

      *)
        # Unexpected status
        echo "ERROR: Unexpected status of thread $t"
        exit 1
        ;;
    esac
  done
  if test -z "$RUNNING_THREADS"; then
    # Setup completed
    break
  fi
  echo "Running threads $RUNNING_THREADS"
done

# Write the output
cat >$OUTPUT_FILE <<!
export DOCKER_REGISTRY='$(state_get DOCKER_REGISTRY)'
export JAVA_HOME=$(state_get JAVA_HOME)
export PATH=$(state_get JAVA_HOME)/bin:$PATH
export ORDER_DB_NAME='$(state_get ORDER_DB_NAME)'
export ORDER_DB_TNS_ADMIN='$(state_get ORDER_DB_TNS_ADMIN)'
export ORDER_DB_ALIAS='$(state_get ORDER_DB_ALIAS)'
export INVENTORY_DB_NAME='$(state_get INVENTORY_DB_NAME)'
export INVENTORY_DB_TNS_ADMIN='$(state_get INVENTORY_DB_TNS_ADMIN)'
export INVENTORY_DB_ALIAS='$(state_get INVENTORY_DB_ALIAS)'
export OCI_REGION='$(state_get OCI_REGION)'
export VAULT_SECRET_OCID=''
export K8S_NAMESPACE='msdataworkshop'
!