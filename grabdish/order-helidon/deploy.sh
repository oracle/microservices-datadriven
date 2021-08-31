#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

SCRIPT_DIR=$(dirname $0)

if [ -z "$DOCKER_REGISTRY" ]; then
    echo "DOCKER_REGISTRY not set. Will get it with state_get"
  export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)
fi

if [ -z "$DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi

if [ -z "$ORDER_PDB_NAME" ]; then
    echo "ORDER_PDB_NAME not set. Will get it with state_get"
  export ORDER_PDB_NAME=$(state_get ORDER_DB_NAME)
fi

if [ -z "$ORDER_PDB_NAME" ]; then
    echo "Error: ORDER_PDB_NAME env variable needs to be set!"
    exit 1
fi

echo create order-helidon deployment and service...
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml

cp order-helidon-deployment.yaml order-helidon-deployment-$CURRENTTIME.yaml

sed -e "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" order-helidon-deployment-${CURRENTTIME}.yaml > /tmp/order-helidon-deployment-${CURRENTTIME}.yaml
mv -- /tmp/order-helidon-deployment-$CURRENTTIME.yaml order-helidon-deployment-$CURRENTTIME.yaml
sed -e "s|%ORDER_PDB_NAME%|${ORDER_PDB_NAME}|g" order-helidon-deployment-${CURRENTTIME}.yaml > /tmp/order-helidon-deployment-${CURRENTTIME}.yaml
mv -- /tmp/order-helidon-deployment-$CURRENTTIME.yaml order-helidon-deployment-$CURRENTTIME.yaml
sed -e "s|%OCI_REGION%|${OCI_REGION}|g" order-helidon-deployment-${CURRENTTIME}.yaml > /tmp/order-helidon-deployment-$CURRENTTIME.yaml
mv -- /tmp/order-helidon-deployment-$CURRENTTIME.yaml order-helidon-deployment-$CURRENTTIME.yaml
sed -e "s|%VAULT_SECRET_OCID%|${VAULT_SECRET_OCID}|g" order-helidon-deployment-${CURRENTTIME}.yaml > /tmp/order-helidon-deployment-$CURRENTTIME.yaml
mv -- /tmp/order-helidon-deployment-$CURRENTTIME.yaml order-helidon-deployment-$CURRENTTIME.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/order-helidon-deployment-$CURRENTTIME.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/order-helidon-deployment-$CURRENTTIME.yaml) -n msdataworkshop
fi

kubectl apply -f $SCRIPT_DIR/order-service.yaml -n msdataworkshop
