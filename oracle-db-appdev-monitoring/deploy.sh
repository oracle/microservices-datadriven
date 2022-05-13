#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


if [ -z "$DOCKER_REGISTRY" ]; then
    echo "DOCKER_REGISTRY not set. Will get it with state_get"
  export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)
fi

if [ -z "$DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi

if [ -z "$OBSERVABILITY_DB_NAME" ]; then
    echo "INVENTORY_DB_NAME not set. Will get it with state_get"
  export INVENTORY_DB_NAME=$(state_get INVENTORY_DB_NAME)
fi

if [ -z "$INVENTORY_DB_NAME" ]; then
    echo "Error: INVENTORY_DB_NAME env variable needs to be set!"
    exit 1
fi

echo create configmap for oracle-db-appdev-monitoring...
kubectl delete configmap oracle-db-appdev-monitoring-config -n msdataworkshop
kubectl create configmap oracle-db-appdev-monitoring-config --from-file=oracle-db-appdev-monitoring-metrics.toml -n msdataworkshop
echo
echo create db-metrics-exporter deployment and service...

cp oracle-db-appdev-monitoring-deployment_template.yaml oracle-db-appdev-monitoring-deployment.yaml

sed -e  "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" oracle-db-appdev-monitoring-deployment.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
sed -e  "s|%EXPORTER_NAME%|inventorypdb|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
sed -e  "s|%PDB_NAME%|${INVENTORY_DB_NAME}|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
sed -e  "s|%USER%|INVENTORYUSER|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
sed -e  "s|%db-wallet-secret%|inventory-db-tns-admin-secret|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
#sed -e  "s|${OCI_REGION-}|${OCI_REGION}|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
#mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml
#sed -e  "s|${VAULT_SECRET_OCID-}|${VAULT_SECRET_OCID}|g" oracle-db-appdev-monitoring-deployment.yaml.yaml > /tmp/oracle-db-appdev-monitoring-deployment.yaml
#mv -- /tmp/oracle-db-appdev-monitoring-deployment.yaml oracle-db-appdev-monitoring-deployment.yaml

kubectl apply -f $SCRIPT_DIR/oracle-db-appdev-monitoring-deployment.yaml -n msdataworkshop
#todo service could be dynamic as well
kubectl apply -f $SCRIPT_DIR/oracle-db-appdev-monitoring-service.yaml -n msdataworkshop

