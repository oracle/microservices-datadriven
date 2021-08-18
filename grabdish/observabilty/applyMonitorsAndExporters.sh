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


helm install loki-grafana grafana/grafana                               --set persistence.enabled=true,persistence.type=pvc,persistence.size=10Gi                               --namespace=loki-stack
helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi




 573  helm version
  574  helm ini
  575  helm init
  576  helm version
  577  helm upgrade --install loki grafana/loki-stack
  578  helm repo update
  579  helm upgrade --install loki grafana/loki-stack
  580  helm repo add grafana https://grafana.github.io/helm-charts
  581  helm repo update
  582  helm upgrade --install loki grafana/loki-stack
  583  helm upgrade --uninstall loki grafana/loki-stack
  584  helm upgrade --uninstall loki
  585  helm uninstall loki
  586  helm install loki-stack grafana/loki-stack \
  587  helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
  588  pods
  589  helm uninstall loki-stack
  590  history
  591  helm releases
  592  helm ls
  593  k delete ns loki-stack
  594  pods
  595  k delete deployment fluentd
  596  k delete deployment fluentd -n kube-system
  597  k delete deployment tiller-deploy -n kube-system
  598  deployments
  599  services
  600  helm install loki-stack grafana/loki-stack --namespace msdataworkshop --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
  601  helm install loki-grafana grafana/grafana                               --set persistence.enabled=true,persistence.type=pvc,persistence.size=10Gi                               --namespace=loki-stack
  602  helm install loki-stack grafana/loki-stack --create-namespace --namespace loki-stack --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi
  603  helm install loki-grafana grafana/grafana                               --set persistence.enabled=true,persistence.type=pvc,persistence.size=10Gi                               --namespace=loki-stack
  604  services
  605  kubectl get pods -n loki-stack
  606  k logs loki-stack-promtail-98nwc -n loki-stack
  607  deployments
  608  pods
  609  k edit pod loki-stack-promtail-98nwc -n loki-stack
  610  k logs loki-stack-promtail-98nwc -n loki-stack|grep alternatives.log
  611  k logs loki-stack-promtail-98nwc -n loki-stack|grep alternatives
  612  k get rs -all-namespaces
  613  k get rs --all-namespaces
  614  k get rs loki-grafana-6746d444dc -n loki-stack  -o yaml
  615  pods
  616  k get pod loki-stack-promtail-98nwc -n loki-stack -o yaml