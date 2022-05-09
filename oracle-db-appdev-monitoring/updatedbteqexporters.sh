#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo Delete and re-apply configmaps for db metrics exporters...
kubectl delete configmap db-metrics-orderpdb-exporter-config -n msdataworkshop
kubectl delete configmap db-metrics-inventorypdb-exporter-config -n msdataworkshop
kubectl create configmap db-metrics-orderpdb-exporter-config --from-file=./db-metrics-exporter/db-metrics-orderpdb-exporter-metrics.toml -n msdataworkshop
kubectl create configmap db-metrics-inventorypdb-exporter-config --from-file=./db-metrics-exporter/db-metrics-inventorypdb-exporter-metrics.toml -n msdataworkshop
echo
echo Delete and re-apply deployments and services for db metrics exporters...
kubectl delete deployment db-metrics-exporter-orderpdb  -n msdataworkshop
kubectl delete deployment db-metrics-exporter-inventorypdb  -n msdataworkshop
cd db-metrics-exporter
./deploy.sh
cd ../
echo
