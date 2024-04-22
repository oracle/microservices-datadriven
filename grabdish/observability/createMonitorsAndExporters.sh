#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


echo create servicemonitors for microservices and pdbs...

kubectl apply -f ../frontend-helidon/frontend-service-monitor.yaml -n msdataworkshop
kubectl apply -f ../order-helidon/order-service-monitor.yaml -n msdataworkshop
kubectl apply -f ../inventory-helidon/inventory-service-monitor.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter/db-metrics-orderpdb-service-monitor.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter/db-metrics-inventorypdb-service-monitor.yaml -n msdataworkshop
kubectl get ServiceMonitor --all-namespaces
echo
echo create deployments and services for db observability exporters...
cd db-metrics-exporter
./deploy.sh
cd ../
