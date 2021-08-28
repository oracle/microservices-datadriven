#Unified Observability

Run `./install.sh` 
 This will install prometheus, loki, promtail, and Grafana
#
Run `./applyMonitorsAndExporter.sh`
 
 This will create monitors or frontend, order, and inventory services as well as orderpdb and inventorypdb exporter services.
 
 It will then create the orderpdb and inventorypdb exporter toml configmaps, deployments, and services
#
Additional modifications can be made to the following files

    db-metrics-orderpdb-exporter-metrics.toml
    db-metrics-inventorypdb-exporter-metrics.toml
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
Different dashboards for different uses... diagnostics, performance, lower or upper level arch focus, etc.

#
Conduct Queries and Drill-downs


#sample queries
https://grafana.com/docs/loki/latest/logql/

#grafana alerts
https://grafana.com/docs/grafana/latest/alerting/

* it may be possible to provide grafana.ini if we want to remove manual steps
https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources




From https://docs.oracle.com/cd/E18283_01/server.112/e17120/monitoring001.htm#insertedID1 ...
https://docs.oracle.com/en/cloud/paas/database-dbaas-cloud/csdbi/view-alert-logs-and-check-errors-using-dbaas-monitor.html

The alert log is a chronological log of messages and errors, and includes the following items:

All internal errors (ORA-00600), block corruption errors (ORA-01578), and deadlock errors (ORA-00060) that occur

Administrative operations, such as CREATE, ALTER, and DROP statements and STARTUP, SHUTDOWN, and ARCHIVELOG statements

Messages and errors relating to the functions of shared server and dispatcher processes

Errors occurring during the automatic refresh of a materialized view

The values of all initialization parameters that had nondefault values at the time the database and instance start