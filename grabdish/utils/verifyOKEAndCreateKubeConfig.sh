#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo verifying OKE cluster creation,  create ~/.kube/config, create msdataworkshop namespace, and set Jaeger UI Address ...
echo this script requires that createOKECluster.sh has already been run in order to set the compartmentid  ...
echo ________________________________________

export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

export MSDATAWORKSHOP_REGION=$(cat $WORKINGDIR/msdataworkshopregion.txt)
echo MSDATAWORKSHOP_REGION... $MSDATAWORKSHOP_REGION

export MSDATAWORKSHOP_COMPARTMENT_ID=$(cat $WORKINGDIR/msdataworkshopcompartmentid.txt)
echo MSDATAWORKSHOP_COMPARTMENT_ID... $MSDATAWORKSHOP_COMPARTMENT_ID
echo
oci ce cluster list --compartment-id $MSDATAWORKSHOP_COMPARTMENT_ID --lifecycle-state ACTIVE | jq '.data[]  | select(.name == "msdataworkshopcluster") | .id' | tr -d '"' > $WORKINGDIR/msdataworkshopclusterid.txt
cat $WORKINGDIR/msdataworkshopclusterid.txt
export MSDATAWORKSHOP_CLUSTER_ID=$(cat $WORKINGDIR/msdataworkshopclusterid.txt)
echo MSDATAWORKSHOP_CLUSTER_ID... $MSDATAWORKSHOP_CLUSTER_ID

if [[ $MSDATAWORKSHOP_CLUSTER_ID == "" ]]
then
  echo "MSDATAWORKSHOP_CLUSTER_ID does not exist. OKE may still be provisioning. Try again or check the OCI console for progress."
else
  export CURRENTTIME=$( date '+%F_%H:%M:%S' )
  echo backing up existing ~/.kube/config, if any, to ~/.kube/config-$CURRENTTIME
  cp ~/.kube/config ~/.kube/config-$CURRENTTIME
  echo creating ~/.kube/config ...
  oci ce cluster create-kubeconfig --cluster-id $MSDATAWORKSHOP_CLUSTER_ID --file $HOME/.kube/config --region $MSDATAWORKSHOP_REGION --token-version 2.0.0
  echo create msdataworkshop namespace...
  kubectl create ns msdataworkshop
fi
