#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl apply -f prom_rbac.yaml -n msdataworkshop
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop
kubectl --namespace msdataworkshop get pods -l "release=stable"
kubectl get prometheus -n msdataworkshop
kubectl patch svc stable-kube-prometheus-sta-prometheus -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop
kubectl patch svc stable-grafana -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop
kubectl apply -f prom_msdataworkshop_servicemonitor.yaml -n msdataworkshop
#kubectl delete configmap db-teq-exporter-config  -n msdataworkshop
kubectl create configmap db-teq-exporter-config --from-file=./db-teq-exporter-metrics.toml -n msdataworkshop
kubectl describe configmap db-teq-exporter-config -n msdataworkshop
kubectl get configmap db-teq-exporter-config  -n msdataworkshop -o yaml
kubectl apply -f db-teq-exporter-deployment.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-service.yaml -n msdataworkshop

kubectl apply -f grafana.yaml -n msdataworkshop
# admin/prom-operator
#MicroProfile https://grafana.com/grafana/dashboards/12853
#Fault Tolerance https://grafana.com/grafana/dashboards/8022


#docker run -d --name oracledb_exporter --link=oracle -p 9161:9161
#--env-file /Users/pparkins/go/src/orahub/ora-jdbc-dev/aqkafka-java-client/scripts/monitoring/.envtest
#-v /Users/pparkins/go/src/orahub/ora-jdbc-dev/aqkafka-java-client/scripts/monitoring/exporter/default-metrics.toml:/default-metrics.toml
#iamseth/oracledb_exporter
#
#DATA_SOURCE_NAME=system/oracle@oracle/xe
#CUSTOM_METRICS=/default-metrics.toml
