#Unified Observability

Run `./install.sh` 
 This will install prometheus, loki, promtail, and Grafana
#
Run `./applyMonitorsAndExporter.sh`
 
 This will create monitors or frontend, order, and inventory services as well as orderpdb and inventorypdb exporter services.
 
 It will then create the orderpdb and inventorypdb exporter toml configmaps, deployments, and services
#
Additional modifications can be made to the following files

    db-teq-orderpdb-exporter-metrics.toml
    db-teq-inventorypdb-exporter-metrics.toml
 and `./createMonitorsAndDBExporters.sh` can be run  to apply them
    
#

Open Grafana. 

`kubectl get service stable-grafana -n msdataworkshop`
 login: admin/prom-operator
This is stored in `stable-grafana` secret.

Select `Configuration` gear and `DataSources` and datasources and URLs

    http://loki-stack.loki-stack:3100
    http://jaeger-query-nodeport.msdataworkshop:80
    http://stable-kube-prometheus-sta-prometheus:9090/
    
#
Derived Fields

Name: traceIDFromSpanReported
Regex: Span reported: (\w+)
Query: ${__value.raw}
Internal link: Jaeger

#
Install Dashboard

#
Conduct Queries and Drill-downs




* it may be possible to provide grafana.ini if we want to remove manual steps
