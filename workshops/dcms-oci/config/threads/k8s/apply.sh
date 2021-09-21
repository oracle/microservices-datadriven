#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
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


if ! state_done VNC_OCID; then
  if test $(state_get RUN_TYPE) != "LL"; then
    # Need to provision network
    STATE=$DCMS_INFRA_STATE/network
    mkdir -p $STATE
    cat >$STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
REGION=$(state_get REGION)
VNC_DNS_LABEL=$DCMS_WORKSHOP
!
    provisioning-apply $MSDD_INFRA_CODE/network/oci
    (
      source $STATE/output.env
      state_set VNC_OCID "$VNC_OCID"
    )
  else
    state_set VNC_OCID "NA"
  fi
fi


if ! state_done BYO_OKE_OCID; then
  if test $(state_get RUN_TYPE) == "LL"; then
    # OKE is already provisioned.  Just need to get the OKE OCID
    BYO_OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[?"'"lifecycle-state"'"=='ACTIVE'].id)" --raw-output`
    state_set BYO_OKE_OCID "$BYO_OKE_OCID"
  else
    state_set BYO_OKE_OCID "NA"
  fi
fi


# Provision OKE
STATE=$DCMS_INFRA_STATE/k8s
mkdir -p $STATE
cd $STATE
cat >$STATE/input.env <<!
BYO_OKE_OCID=$(state_get BYO_OKE_OCID)
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
REGION=$(state_get REGION)
TENANCY_OCID=$(state_get TENANCY_OCID)
VNC_OCID=$(state_get VNC_OCID)
!
provisioning-apply $MSDD_INFRA_CODE/k8s/oke_new


(
source $STATE/output.env
state_set OKE_OCID "$OKE_OCID"
)


echo "" > $OUTPUT_FILE
state_set_done K8S_THREAD