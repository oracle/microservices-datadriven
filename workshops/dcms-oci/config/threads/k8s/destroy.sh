#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Wait for dependencies to be undone
DEPENDENCIES='GRABDISH_THREAD'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES to be undone"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  sleep 1
done

# Destroy OKE and network (unless Live Labs)
if ! test $(state_get RUN_TYPE) == "LL"; then
  # Destroy OKE
  cd $DCMS_INFRA_STATE/k8s
  provisioning-destroy

  # Wait for dependencies to be undone
  DEPENDENCIES='DB_THREAD'
  while ! test -z "$DEPENDENCIES"; do
    echo "Waiting for $DEPENDENCIES to be undone"
    WAITING_FOR=""
    for d in $DEPENDENCIES; do
      if state_done $d; then
        WAITING_FOR="$WAITING_FOR $d"
      fi
    done
    DEPENDENCIES="$WAITING_FOR"
    sleep 1
  done

  cd $DCMS_INFRA_STATE/network
  provisioning-destroy
fi


# Delete state file
rm -f $STATE_FILE
state_reset K8S_THREAD