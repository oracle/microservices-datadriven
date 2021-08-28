#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl delete configmap db-metrics-orderpdb-exporter-config -n msdataworkshop
kubectl delete configmap db-metrics-inventorypdb-exporter-config -n msdataworkshop
kubectl create configmap db-metrics-orderpdb-exporter-config --from-file=./db-metrics-orderpdb-exporter-metrics.toml -n msdataworkshop
kubectl create configmap db-metrics-inventorypdb-exporter-config --from-file=./db-metrics-inventorypdb-exporter-metrics.toml -n msdataworkshop
kubectl delete deployment db-metrics-exporter-order  -n msdataworkshop
kubectl delete deployment db-metrics-exporter-inventory  -n msdataworkshop
kubectl apply -f db-metrics-exporter-orderpdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-metrics-exporter-inventorypdb-deployment.yaml -n msdataworkshop
