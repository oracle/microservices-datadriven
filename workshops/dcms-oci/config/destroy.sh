#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


export DCMS_INFRA_STATE=$DCMS_STATE/infra
export DCMS_APP_STATE=$DCMS_STATE/grabdish
export DCMS_THREAD_STATE=$DCMS_STATE/threads


# Start the background destroy threads
THREADS="db build-prep k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  mkdir -p $THREAD_STATE
  cd $THREAD_STATE
  nohup bash -c "provisioning-destroy" >> $DCMS_LOG_DIR/$t-thread.log 2>&1 &
done


# Check the threads
while true; do
  sleep 10
  RUNNING_THREADS=''
  for t in $THREADS; do
    THREAD_STATE=$DCMS_THREAD_STATE/$t
    STATUS=$(provisioning-get-status $THREAD_STATE)
    case "$STATUS" in
      new | destroyed | byo)
        # Nothing to do
        ;;

      destroying)
        RUNNING_THREADS="$RUNNING_THREADS $t"
        ;;

      destroying-failed)
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

rm -f $STATE_FILE

# Remove the source.env from the .bashrc
PROF=~/.bashrc
if test -f "$PROF"; then
  sed -i.bak '/microservices-datadriven/d' $PROF
fi

# Clean up the auth token
TOKEN_OCID=$(oci iam auth-token list --region "$(state_get HOME_REGION)" --user-id="$(state_get USER_OCID)" --query 'data[?description=='"'$(state_get DOCKER_AUTH_TOKEN_DESC)'"'].id|[0]' --raw-output)
oci iam auth-token delete --region "$(state_get HOME_REGION)" --user-id="$(state_get USER_OCID)" --force --auth-token-id "$TOKEN_OCID"
