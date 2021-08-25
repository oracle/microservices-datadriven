#Unified Observability

Run ./install.sh 
 This will install prometheus, loki, promtail, and Grafana

Run ./applyMonitorsAndExporter.sh 
 This will create monitors or frontend, order, and inventory services as well as orderpdb and inventorypdb exporter services.
 It will then create the orderpdb and inventorypdb exporter toml configmaps, deployments, and services

Adding

