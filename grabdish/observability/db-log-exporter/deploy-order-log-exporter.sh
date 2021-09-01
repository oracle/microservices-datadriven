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

echo create db-log-exporter deployment and service...
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml

cp db-log-exporter-deployment.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml

sed -e  "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%EXPORTER_NAME%|orderpdb|g" db-log-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%PDB_NAME%|${ORDER_PDB_NAME}|g" db-log-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%USER%|orderUSER|g" db-log-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%OCI_REGION%|${OCI_REGION}|g" db-log-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%VAULT_SECRET_OCID%|${VAULT_SECRET_OCID}|g" db-log-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/db-log-exporter-orderpdb-deployment-$CURRENTTIME.yaml) -n msdataworkshop
fi

kubectl apply -f $SCRIPT_DIR/db-log-orderpdb-exporter-service.yaml -n msdataworkshop
