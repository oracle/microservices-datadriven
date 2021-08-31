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
echo create configmaps for db metrics exporters...
kubectl create configmap db-metrics-orderpdb-exporter-config --from-file=./db-metrics-exporter/db-metrics-orderpdb-exporter-metrics.toml -n msdataworkshop
kubectl create configmap db-metrics-inventorypdb-exporter-config --from-file=./db-metrics-exporter/db-metrics-inventorypdb-exporter-metrics.toml -n msdataworkshop
# informational only...
#kubectl describe configmap db-metrics-exporter-config -n msdataworkshop
#kubectl get configmap db-metrics-exporter-config  -n msdataworkshop -o yaml
# apply the deployments and services for the pdb exporters...
echo create deployments and services for db metrics exporters...
kubectl apply -f db-metrics-exporter/db-metrics-exporter-orderpdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter/db-metrics-exporter-orderpdb-service.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter/db-metrics-exporter-inventorypdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter/db-metrics-exporter-inventorypdb-service.yaml -n msdataworkshop
echo
echo create deployments and services for db metrics exporters...
cd db-metrics-exporter
./deploy.sh
cd ../
echo
echo create deployments and services for db log exporters...
cd db-log-exporter
./deploy.sh
cd ../

