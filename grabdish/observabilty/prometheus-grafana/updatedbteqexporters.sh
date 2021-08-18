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

kubectl create configmap alert-log-config --from-file=./alert.log -n msdataworkshop

kubectl delete configmap promtail-config  -n msdataworkshop
kubectl create configmap promtail-config --from-file=promtail.yaml -n msdataworkshop
k delete deployment alert-log -n msdataworkshop
kubectl apply -f alert-log-deployment.yaml -n msdataworkshop

kubectl apply -f alert-log-service.yaml -n msdataworkshop



#same in loki-stack ns...

kubectl create configmap alert-log-config --from-file=./alert.log -n loki-stack
kubectl delete configmap promtail-config  -n loki-stack
kubectl create configmap promtail-config --from-file=promtail.yaml -n loki-stack
k delete deployment alert-log -n loki-stack
kubectl apply -f alert-log-deployment.yaml -n loki-stack
kubectl apply -f alert-log-service.yaml -n loki-stack




kubectl create configmap positions-config --from-file=positions.yaml -n msdataworkshop