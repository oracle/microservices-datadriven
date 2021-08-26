#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl create configmap alert-log-config --from-file=./alert.log -n msdataworkshop
kubectl delete configmap promtail-config  -n msdataworkshop
kubectl create configmap promtail-config --from-file=promtail.yaml -n msdataworkshop
kubectl delete deployment alert-log -n msdataworkshop
kubectl apply -f alert-log-deployment.yaml -n msdataworkshop

kubectl apply -f alert-log-service.yaml -n msdataworkshop



#same in loki-stack ns...

kubectl create configmap alert-log-config --from-file=./alert.log -n loki-stack
kubectl delete configmap promtail-config  -n loki-stack
kubectl create configmap promtail-config --from-file=promtail.yaml -n loki-stack
kubectl delete deployment alert-log -n loki-stack
kubectl apply -f alert-log-deployment.yaml -n loki-stack
kubectl apply -f alert-log-service.yaml -n loki-stack




kubectl create configmap positions-config --from-file=positions.yaml -n msdataworkshop