#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl delete configmap db-teq-exporter-config -n msdataworkshop
kubectl create configmap db-teq-exporter-config --from-file=./db-teq-grabdish-exporter-metrics.toml -n msdataworkshop
# informational only...
#kubectl describe configmap db-teq-exporter-config -n msdataworkshop
#kubectl get configmap db-teq-exporter-config  -n msdataworkshop -o yaml
# apply the deployments and services for the pdb exporters...
kubectl apply -f db-teq-exporter-orderpdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-inventorypdb-deployment.yaml -n msdataworkshop
#todo verify deployment is considered changed if the configmap it uses has been updated or if it's necessary to delete/apply the deployment