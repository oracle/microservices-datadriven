---
title: Oracle Database Metrics Exporter
sidebar_position: 6
---
## Oracle Database Metrics Exporter

The Oracle Database Metrics Exporter is a key observability component that provides comprehensive metrics collection for Oracle Database. It helps users understand database performance and diagnose issues easily across applications and the database, supporting both cloud and on-premises deployments, including databases running in Kubernetes and containers.

:::info Complete Documentation Available
This exporter is documented in detail in the **[Platform Components](../platform/dbexporter.md)** section. For complete installation instructions, testing procedures, troubleshooting guidance, and dashboard configuration, please refer to the comprehensive guide:

**[→ Oracle Database Metrics Exporter - Full Documentation](../platform/dbexporter.md)**
:::

## Quick Links

- **[Installation Guide](../platform/dbexporter.md#installing-oracle-database-metrics-exporter)** - Enable and deploy the exporter
- **[Testing Guide](../platform/dbexporter.md#testing-oracle-database-metrics-exporter)** - Verify metrics collection
- **[Dashboards](../platform/dbexporter.md#dashboards)** - View pre-built Grafana dashboards
- **[Troubleshooting](../platform/dbexporter.md#troubleshooting)** - Common issues and solutions
- **[Official Documentation](https://github.com/oracle/oracle-db-appdev-monitoring)** - Oracle's GitHub repository

## What Metrics Are Available

The exporter provides Prometheus-formatted metrics including:

- **Database connectivity** - `oracledb_up` - Database instance reachability
- **Session metrics** - `oracledb_sessions_*` - Active sessions and session statistics
- **Tablespace metrics** - `oracledb_tablespace_*` - Tablespace usage and capacity
- **Activity metrics** - `oracledb_activity_*` - Database activity and performance
- **Transactional Event Queue metrics** - TxEventQ throughput and queue statistics

These metrics are exposed on port 9161 and automatically scraped by Prometheus when properly configured.

## Integration with OBaaS Observability

The Database Metrics Exporter integrates seamlessly with the OBaaS observability stack:

1. **Prometheus** automatically discovers and scrapes metrics from the exporter
2. **SigNoz** provides pre-built dashboards for visualizing database performance
3. **Service Discovery** ensures metrics are collected from all database instances
4. **Alert Manager** can trigger alerts based on database metric thresholds

For the complete setup and configuration, see the **[full documentation](../platform/dbexporter.md)**.

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
