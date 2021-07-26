#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# install serviceaccount, clusterrole, and clusterrole binding needed for prometheus (default pw is admin/prom-operator)
kubectl apply -f install/prom_rbac.yaml -n msdataworkshop
# install prometheus...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack --namespace=msdataworkshop
# informational only...
#kubectl --namespace msdataworkshop get pods -l "release=stable"
#kubectl get prometheus -n msdataworkshop
# change NP to LB...
kubectl patch svc stable-kube-prometheus-sta-prometheus -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop
# install grafana...
kubectl apply -f grafana.yaml -n msdataworkshop
# change NP to LB...
kubectl patch svc stable-grafana -p '{"spec": {"type": "LoadBalancer"}}' -n msdataworkshop

