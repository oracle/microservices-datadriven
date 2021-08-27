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
if state_done K8S_THREAD; then
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


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID REGION OKE_LIMIT_CHECK'
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


K8S_HOME=$DCMS_INFRA_HOME/k8s
mkdir -p $K8S_HOME
if ! test -f $K8S_HOME/output.env; then
  cat >$K8S_HOME/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
REGION=$(state_get REGION)
!
  $MSDD_CODE_HOME/infra/k8s/oke/setup.sh $K8S_HOME
fi

if ! test -f $K8S_HOME/output.env; then
  echo "ERROR: k8s provisioning failed"
  exit
fi

 
(
source $OKE_HOME/output.env
set_state OKE_OCID "$OKE_OCID"
)


set_state_done DB_THREAD