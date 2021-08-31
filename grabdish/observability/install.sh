#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo Installing Jaeger...
#./jaeger/jaeger-setup.sh
kubectl create -f install/jaeger-all-in-one-template.yml -n msdataworkshop
echo

echo Installing ServiceAccount, ClusterRole, and ClusterRole binding needed for Prometheus
kubectl apply -f install/prom_rbac.yaml -n msdataworkshop
echo

echo Installing Prometheus...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop
echo

echo Installing Grafana...
kubectl apply -f install/grafana.yaml -n msdataworkshop
# todo remove need to change NP to LB and use ingress instead
kubectl patch svc stable-grafana -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop
echo

echo Installing loki-stack with Promtail...
helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
echo


kubectl create -f install/grafana-ingress.yaml -n msdataworkshop