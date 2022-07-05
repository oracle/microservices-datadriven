#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Fail on error
set -e

echo Installing Jaeger...
kubectl create -f install/jaeger-all-in-one-template.yml -n msdataworkshop
kubectl create -f install/jaeger-ingress.yaml -n msdataworkshop
echo

echo Installing ServiceAccount, ClusterRole, and ClusterRole binding needed for Prometheus
kubectl apply -f install/prom_rbac.yaml -n msdataworkshop
echo

echo Updating Helm Repo...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo Installing Prometheus and custom Grafana ...
helm install stable prometheus-community/kube-prometheus-stack --namespace msdataworkshop -f install/prometheus-stack-values.yaml
#helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop --set grafana.enabled=false
echo

# echo Installing Grafana...
# helm install grafana-lab grafana/grafana --namespace msdataworkshop -f install/grafana-helm-values.yaml
# echo

echo Installing Loki stack with Promtail...
helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
echo
