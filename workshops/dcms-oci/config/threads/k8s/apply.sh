#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID REGION TENANCY_OCID OKE_LIMIT_CHECK'
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


# Provision OKE
STATE=$DCMS_INFRA_STATE/k8s
mkdir -p $STATE
cd $STATE
cat >$STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
REGION=$(state_get REGION)
TENANCY_OCID=$(state_get TENANCY_OCID)
!
provisioning-apply $MSDD_INFRA_CODE/k8s/oke

 
(
source $STATE/output.env
state_set OKE_OCID "$OKE_OCID"
)


echo "" > $OUTPUT_FILE
state_set_done K8S_THREAD