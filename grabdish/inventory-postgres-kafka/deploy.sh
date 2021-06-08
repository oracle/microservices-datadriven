#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

SCRIPT_DIR=$(dirname $0)

export DOCKER_REGISTRY="$(state_get DOCKER_REGISTRY)"
export INVENTORY_PDB_NAME="$(state_get INVENTORY_DB_NAME)"
export OCI_REGION="$(state_get OCI_REGION)"
export VAULT_SECRET_OCID=""

echo create inventory-postgres-kafka deployment and service...

export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml
cp inventory-postgres-kafka-deployment.yaml inventory-postgres-kafka-deployment-$CURRENTTIME.yaml

#may hit sed incompat issue with mac
sed -i "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" inventory-postgres-kafka-deployment-$CURRENTTIME.yaml
sed -i "s|%INVENTORY_PDB_NAME%|${INVENTORY_PDB_NAME}|g" inventory-postgres-kafka-deployment-$CURRENTTIME.yaml
sed -i "s|%OCI_REGION%|${OCI_REGION}|g" inventory-postgres-kafka-deployment-${CURRENTTIME}.yaml
sed -i "s|%VAULT_SECRET_OCID%|${VAULT_SECRET_OCID}|g" inventory-postgres-kafka-deployment-${CURRENTTIME}.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/inventory-postgres-kafka-deployment-$CURRENTTIME.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/inventory-postgres-kafka-deployment-$CURRENTTIME.yaml) -n msdataworkshop
fi
kubectl delete service supplier  -n msdataworkshop
kubectl apply -f $SCRIPT_DIR/supplier-service.yaml  -n msdataworkshop # temporarily for inventory adjustment, will use inventory service
kubectl apply -f $SCRIPT_DIR/inventory-service.yaml  -n msdataworkshop # for various including setting of failures and eventually inventory adjustment calls, etc.
