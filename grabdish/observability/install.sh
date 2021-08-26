#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# install serviceaccount, clusterrole, and clusterrole binding needed for prometheus (default pw is admin/prom-operator)
kubectl apply -f prom_rbac.yaml -n msdataworkshop
# install prometheus...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop
# informational only...
#kubectl --namespace msdataworkshop get pods -l "release=stable"
#kubectl get prometheus -n msdataworkshop
# change NP to LB...
#kubectl patch svc stable-kube-prometheus-sta-prometheus -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop
# install grafana...
kubectl apply -f grafana.yaml -n msdataworkshop
# change NP to LB...
kubectl patch svc stable-grafana -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop

#helm install loki-grafana grafana/grafana                               --set persistence.enabled=true,persistence.type=pvc,persistence.size=10Gi                               --namespace=loki-stack
helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
