---
title: Introduction and Overview
sidebar_position: 1
---
## Overview

Oracle Backend for Microservices and AI includes SigNoz which is a observability platform to collect and provide access to logs. metrics and traces for the platform itself and for your applications.

The diagram below provides an overview of the SigNoz:

![Observability Overview](images/observability-overview.png)

In the diagram above:

- You may deploy applications into the platform and can either send the metrics, logs and traces to SigNoz OpenTelemetry collector or configure annotations on the application pod fo SigNoz to scrape metrics endpoints from the application pod directly. Similarly traces can be generated and sent to the SigNoz OpenTelemetry collector using the OpenTelemetry SDK. Please refer to [OpenTelemetry Collector - architecture and configuration guide](https://signoz.io/blog/opentelemetry-collector-complete-guide/) for details.
- The [Oracle Database Exporter](https://github.com/oracle/oracle-db-appdev-monitoring) and Kube State Metrics are pre-installed and SigNoz is configured to collect metrics from them.
- SigNoz populated with a set of dashboards (some of them are described below).

:::note
More details can be found in the [SigNoz Documentation](https://signoz.io/docs/introduction/).
:::
