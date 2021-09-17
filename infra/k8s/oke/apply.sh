#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


if test "$BYO_OKE_OCID" =~ ^ocid1\.cluster; then
  # OKE has been provisioned already
  OKE_OCID=$BYO_OKE_OCID
else
  # Provision OKE
  cp -rf $MY_CODE/terraform $MY_STATE
  cd $MY_STATE/terraform
  export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
  export TF_VAR_ociRegionIdentifier="$REGION"
  export TF_VAR_ociTenancyOcid="$TENANCY_OCID"

  if ! terraform init; then
      echo 'ERROR: terraform init failed!'
      exit
  fi

  if ! terraform apply -auto-approve; then
      echo 'ERROR: terraform apply failed!'
      exit
  fi

  # Get the OKE_OCID
  OKE_OCID=`terraform output -raw oke_ocid`
fi


#Setup kukbctl
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


cat >$OUTPUT_FILE <<!
OKE_OCID='$OKE_OCID'
!