#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   oci CLI (configured)
#   MSDD_CODE_HOME (set)
#   
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
#   $1/input.env
#     COMPARTMENT_OCID
#     REGION
#     
# OUTPUTS:
#   $1/output.env
#     OKE_OCID


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Check home is set
if test -z "$MSDD_CODE_HOME"; then
  echo "ERROR: This script requires MSDD_CODE_HOME to be set"
  exit
fi
MY_CODE=$MSDD_CODE_HOME/infra/k8s/oke


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit
fi


# Source input.env
if test -f $MY_HOME/input.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit
fi


cp -rf $MY_CODE/terraform $MY_HOME
cd $MY_HOME/terraform

export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_ociRegionIdentifier="$(state_get REGION)"

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit
fi

if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit
fi

#Setup kukbctl
OKE_OCID=`terraform output oke_ocid`
oci ce cluster create-kubeconfig --cluster-id "$OKE_OCID" --file $HOME/.kube/config --region "$REGION" --token-version 2.0.0


# Wait for OKE nodes to become ready
while true; do
  READY_NODES=`kubectl get nodes | grep Ready | wc -l` || echo 'Ignoring any Error'
  if test "$READY_NODES" -ge 3; then
    echo "3 OKE nodes are ready"
    break
  fi
  echo "Waiting for OKE nodes to become ready"
  sleep 10
done


cat >$MY_HOME/output.env <<!
OKE_OCID='$OKE_OCID'
!