#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

SCRIPT_DIR=$(dirname "$0")

export DOCKER_REGISTRY="$(state_get DOCKER_REGISTRY)"
export INVENTORY_PDB_NAME="$(state_get INVENTORY_DB_NAME)"
export OCI_REGION="$(state_get OCI_REGION)"
export VAULT_SECRET_OCID=""

echo create inventory-springboot deployment...
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml

cp inventory-springboot-deployment.yaml inventory-springboot-deployment-$CURRENTTIME.yaml

IMAGE_NAME="inventory-springboot"
IMAGE_VERSION="0.1"

sed_i "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g;s|%IMAGE_NAME%|${IMAGE_NAME}|g;s|%IMAGE_VERSION%|${IMAGE_VERSION}|g"  inventory-springboot-deployment-${CURRENTTIME}.yaml
sed_i "s|%INVENTORY_PDB_NAME%|${INVENTORY_PDB_NAME}|g" inventory-springboot-deployment-${CURRENTTIME}.yaml
sed_i "s|%OCI_REGION%|${OCI_REGION}|g" inventory-springboot-deployment-${CURRENTTIME}.yaml
sed_i "s|%VAULT_SECRET_OCID%|${VAULT_SECRET_OCID}|g" inventory-springboot-deployment-${CURRENTTIME}.yaml

if [ -z "$1" ]; then
    kubectl apply -f "$SCRIPT_DIR"/inventory-springboot-deployment-${CURRENTTIME}.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f "$SCRIPT_DIR"/inventory-springboot-deployment-${CURRENTTIME}.yaml) -n msdataworkshop
fi
