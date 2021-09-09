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

echo Installing Prometheus...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop
echo

echo Installing Grafana...
kubectl apply -f install/grafana.yaml -n msdataworkshop
#todo instead of LB... kubectl apply -f install/grafana-ingress.yaml -n ingress-nginx
kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop
kubectl apply -f install/grafana-service.yaml -n msdataworkshop
echo

echo Installing loki-stack with Promtail...
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
echo
