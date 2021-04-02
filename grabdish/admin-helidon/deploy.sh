#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

SCRIPT_DIR=$(dirname $0)

echo create admin-helidon deployment and service...
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml

cp admin-helidon-deployment.yaml admin-helidon-deployment-$CURRENTTIME.yaml

sed -i "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%ORDER_PDB_NAME%|${ORDER_PDB_NAME}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%INVENTORY_PDB_NAME%|${INVENTORY_PDB_NAME}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%OCI_REGION%|${OCI_REGION}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%VAULT_SECRET_OCID%|${VAULT_SECRET_OCID}|g" admin-helidon-deployment-${CURRENTTIME}.yaml

echo conducting setup required to create dblinks in OCI....
./setupForDBLinksInCloud.sh

echo  attempting to deploy admin-helidon-deployment-${CURRENTTIME}.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/admin-helidon-deployment-${CURRENTTIME}.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/admin-helidon-deployment-${CURRENTTIME}.yaml) -n msdataworkshop
fi

kubectl apply -f $SCRIPT_DIR/admin-helidon-service.yaml -n msdataworkshop

