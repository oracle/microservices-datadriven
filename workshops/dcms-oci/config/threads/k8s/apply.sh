#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID OCI_REGION TENANCY_OCID OKE_LIMIT_CHECK'
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


# Provision the VCN, unless live labs
if ! state_done VCN_OCID; then
  if test $(state_get RUN_TYPE) != "LL"; then
    # Need to provision network
    STATE=$DCMS_INFRA_STATE/network
    mkdir -p $STATE
    cd $STATE
    cat >$STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
OCI_REGION=$(state_get OCI_REGION)
VCN_DNS_LABEL=dcmsoci
!
    provisioning-apply $MSDD_INFRA_CODE/network/oci
    (
      source $STATE/output.env
      state_set VCN_OCID "$VCN_OCID"
    )
  else
    state_set VCN_OCID "NA"
  fi
fi


# Provision OKE
if test $(state_get RUN_TYPE) == "LL"; then
  # OKE is already provisioned.  Just need to get the OKE OCID and configure kubectl
  OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[?"'"lifecycle-state"'"=='ACTIVE'].id)" --raw-output`
  oci ce cluster create-kubeconfig --cluster-id "$OKE_OCID" --file $HOME/.kube/config --region "$REGION" --token-version 2.0.0
else
  STATE=$DCMS_INFRA_STATE/k8s
  mkdir -p $STATE
  cd $STATE
  cat >$STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
OCI_REGION=$(state_get OCI_REGION)
TENANCY_OCID=$(state_get TENANCY_OCID)
VCN_OCID=$(state_get VCN_OCID)
!
  provisioning-apply $MSDD_INFRA_CODE/k8s/oke
fi

echo "" > $OUTPUT_FILE
state_set_done K8S_THREAD