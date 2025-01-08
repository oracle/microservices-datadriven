+++
archetype = "page"
title = "Database Monitoring Exporter"
weight = 2
+++

[The Oracle Database Metrics Exporter](https://github.com/oracle/oracle-db-appdev-monitoring) is a standalone application that provides observability to Oracle Database instances and is designed to run on-premises or in the cloud. This section covers configuring the database exporter for Oracle Database Transactional Event Queues.

To get started with the database exporter, see the [installation](https://github.com/oracle/oracle-db-appdev-monitoring/blob/main/README.md#installation) section.

* [Exporting TxEventQ Metrics](#exporting-txeventq-metrics)
* [Sample Grafana Dashboard](#sample-grafana-dashboard)

## Exporting TxEventQ Metrics

The database exporter supports [custom metric definitions](https://github.com/oracle/oracle-db-appdev-monitoring/tree/main?tab=readme-ov-file#custom-metrics) in the form of TOML files. The [TxEventQ custom metrics file](https://github.com/oracle/oracle-db-appdev-monitoring/blob/main/custom-metrics-example/txeventq-metrics.toml) contains metrics definitions for queue information like total number of queues, enqueued messages, dequeued messages, and more. You can include the TxEventQ metrics in the database exporter by using the `custom.metrics` program argument and passing the file location:

```text
--custom.metrics=txeventq-metrics.toml
```

Or, set the `CUSTOM_METRICS` environment variable to point to custom metric files:

```text
CUSTOM_METRICS=txeventq-metrics.toml
```

To add more TxEventQ metrics, you can create a custom metrics file based on the views described in the [TxEventQ Administrative Views](./views.md) section and then provide that file to the database exporter.

## Sample Grafana Dashboard

The [Sample Dashboard for TxEventQ](https://github.com/oracle/oracle-db-appdev-monitoring/blob/main/docker-compose/grafana/dashboards/txeventq.json) visualizes database queueing metrics, and requires the custom metrics definitions located in the [TxEventQ custom metrics file](https://github.com/oracle/oracle-db-appdev-monitoring/blob/main/custom-metrics-example/txeventq-metrics.toml) to be loaded into the database exporter.

The dashboard can be loaded into a Grafana instance to visualize TxEventQ status, throughput, and subscriber information for a given queue.

![Sample Dashboard for TxEventQ](../images/TxEventQGrafana.png " ")
