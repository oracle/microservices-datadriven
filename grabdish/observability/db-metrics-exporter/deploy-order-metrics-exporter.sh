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

if [ -z "$ORDER_DB_NAME" ]; then
    echo "ORDER_DB_NAME not set. Will get it with state_get"
  export ORDER_DB_NAME=$(state_get ORDER_DB_NAME)
fi

if [ -z "$ORDER_DB_NAME" ]; then
    echo "Error: ORDER_DB_NAME env variable needs to be set!"
    exit 1
fi

echo create configmap for db-metrics-orderpdb-exporter...
kubectl delete configmap db-metrics-orderpdb-exporter-config -n msdataworkshop
kubectl create configmap db-metrics-orderpdb-exporter-config --from-file=db-metrics-orderpdb-exporter-metrics.toml -n msdataworkshop
echo
echo create db-metrics-exporter deployment and service...
export CURRENTTIME=generated

cp db-metrics-exporter-deployment.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml

#sed -e  "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
#mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%EXPORTER_NAME%|orderpdb|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%PDB_NAME%|${ORDER_DB_NAME}|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%USER%|admin|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
sed -e  "s|%db-wallet-secret%|order-db-tns-admin-secret|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
#sed -e  "s|${OCI_REGION-}|${OCI_REGION}|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
#mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
#sed -e  "s|${VAULT_SECRET_OCID-}|${VAULT_SECRET_OCID}|g" db-metrics-exporter-orderpdb-deployment-${CURRENTTIME}.yaml > /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml
#mv -- /tmp/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/db-metrics-exporter-orderpdb-deployment-$CURRENTTIME.yaml) -n msdataworkshop
fi
#todo service could be dynamic as well
kubectl apply -f $SCRIPT_DIR/db-metrics-exporter-orderpdb-service.yaml -n msdataworkshop
