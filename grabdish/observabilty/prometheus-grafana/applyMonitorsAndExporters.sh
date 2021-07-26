#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


# create servicemonitors for microservices and pdbs...
kubectl apply -f prom_msdataworkshop_servicemonitors.yaml -n msdataworkshop
# create configmap from db-teq-*-exporter-metrics.toml for order and inventory pdb exporters
# this db-teq-exporter-metrics.toml is currently a combination of...
#   - some metrics from https://github.com/iamseth/oracledb_exporter/blob/master/default-metrics.toml (with
#   - some metrics from https://orahub.oci.oraclecorp.com/ora-jdbc-dev/aqkafka-java-client/scripts/monitoring/exporter/default-metrics.toml
#   - mods to these metrics adding ignorezeroresult = true to avoid "Error [...] No metrics found while parsing" source="main.go:269"
#   - additional metrics suited to the Grabdish app (eg inventory levels, message info, etc.)
kubectl create configmap db-teq-orderpdb-exporter-config --from-file=./db-teq-orderpdb-exporter-metrics.toml -n msdataworkshop
kubectl create configmap db-teq-inventorypdb-exporter-config --from-file=./db-teq-inventorypdb-exporter-metrics.toml -n msdataworkshop
# informational only...
#kubectl describe configmap db-teq-exporter-config -n msdataworkshop
#kubectl get configmap db-teq-exporter-config  -n msdataworkshop -o yaml
# apply the deployments and services for the pdb exporters...
kubectl apply -f db-teq-exporter-orderpdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-orderpdb-service.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-inventorypdb-deployment.yaml -n msdataworkshop
kubectl apply -f db-teq-exporter-inventorypdb-service.yaml -n msdataworkshop
