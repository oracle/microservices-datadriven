#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


echo create servicemonitors for microservices and pdbs...

kubectl apply -f db-metrics-exporter/db-metrics-banka-service-monitor.yaml -n msdataworkshop
kubectl get ServiceMonitor --all-namespaces
echo
echo create deployments and services for db metrics exporters...
cd db-metrics-exporter
./deploy.sh
cd ../
export IS_UPDATE=$1
if [ -z "$IS_UPDATE" ]; then
    echo "not an update"
else
    echo "is an update, deletepod to pick up latest configmap in case deployment was unchanged"
    deletepod  db-metrics-exporter-banka
fi

export IS_LOG=$2
if [ -z "$IS_LOG" ]; then
    echo "not IS_LOG"
else
    echo "is IS_LOG, logging pod after 3 second sleep"
    sleep 3
    logpod  db-metrics-exporter-banka
fi
