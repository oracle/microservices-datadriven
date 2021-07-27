#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl delete configmap db-teq-orderpdb-exporter-config -n msdataworkshop
kubectl delete configmap db-teq-inventorypdb-exporter-config -n msdataworkshop
kubectl create configmap db-teq-orderpdb-exporter-config --from-file=./db-teq-orderpdb-exporter-metrics.toml -n msdataworkshop
kubectl create configmap db-teq-inventorypdb-exporter-config --from-file=./db-teq-inventorypdb-exporter-metrics.toml -n msdataworkshop
kubectl delete deployment db-teq-exporter-order  -n msdataworkshop
kubectl delete deployment db-teq-exporter-inventory  -n msdataworkshop
kubectl apply -f db-teq-exporter-orderpdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-inventorypdb-deployment.yaml -n msdataworkshop