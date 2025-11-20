---
title: Oracle Database Metrics Exporter
sidebar_position: 5
---
## Overview

The Oracle Database Metrics Exporter, helps users understand performance and diagnose issues across applications and the database. It targets both cloud and on-premises deployments, including databases running in Kubernetes and containers.

[Full documentation](https://github.com/oracle/oracle-db-appdev-monitoring).

---

## Table of Contents

- [Installing Oracle Database Metrics Exporter](#installing-oracle-database-metrics-exporter)
- [Dashboards](#dashboards)
  - [Oracle Database Grafana Dashboard](#oracle-database-grafana-dashboard)
  - [Transactional Event Queue Grafana Dashboard](#transactional-event-queue-grafana-dashboard)
- [Testing Oracle Database Metrics Exporter](#testing-oracle-database-metrics-exporter)
  - [Verify the exporter is running](#verify-the-exporter-is-running)
  - [Check metrics endpoint](#check-metrics-endpoint)
  - [Verify metrics in Grafana](#verify-metrics-in-grafana)
- [Troubleshooting](#troubleshooting)
  - [Exporter pod not running](#exporter-pod-not-running)
  - [No metrics appearing in Grafana](#no-metrics-appearing-in-grafana)
  - [Database connection errors](#database-connection-errors)

---

### Installing Oracle Database Metrics Exporter

Oracle Database Metrics Exporter will be installed if the `oracle-database-exporter.enabled` is set to `true` in the `values.yaml` file. The default namespace for Oracle Database Metrics Exporter is `oracle-database-exporter`.

---

## Testing Oracle Database Metrics Exporter

:::note Namespace Configuration
All `kubectl` commands in this guide use `-n oracle-database-exporter` as the default namespace. If the Oracle Database Metrics Exporter is installed in a different namespace, replace `oracle-database-exporter` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep oracle-database-exporter
```
:::

### Verify the exporter is running

After installation, verify that the Oracle Database Metrics Exporter pod is running:

```shell
kubectl get pods -n oracle-database-exporter
```

You should see output similar to:

```
NAME                                        READY   STATUS    RESTARTS   AGE
oracle-database-exporter-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

Check the exporter logs to verify it is collecting metrics:

```shell
kubectl logs -n oracle-database-exporter -l app=oracle-database-exporter --tail=50
```

Look for successful metric collection messages and no connection errors.

### Check metrics endpoint

The exporter exposes Prometheus metrics on port 9161. You can verify metrics are being exported:

```shell
kubectl port-forward -n oracle-database-exporter svc/oracle-database-exporter 9161:9161
```

In another terminal, query the metrics endpoint:

```shell
curl -sS http://localhost:9161/metrics
```

You should see Prometheus-formatted metrics including:

- `oracledb_up` - Database connectivity status (1 = up, 0 = down)
- `oracledb_exporter_scrape_duration_seconds` - Scrape duration
- `oracledb_sessions_*` - Session metrics
- `oracledb_tablespace_*` - Tablespace metrics
- `oracledb_activity_*` - Activity metrics

Example output:

```
# HELP oracledb_up Database instance reachable
# TYPE oracledb_up gauge
oracledb_up 1

# HELP oracledb_sessions_value Generic counter metric from v$sesstat view
# TYPE oracledb_sessions_value gauge
oracledb_sessions_value{type="ACTIVE"} 15
```
---

## Troubleshooting

### Exporter pod not running

**Check pod status:**

```shell
kubectl get pods -n oracle-database-exporter
kubectl describe pod -n oracle-database-exporter -l app=oracle-database-exporter
```

**Common causes:**

1. **Image pull errors** - Verify access to the container registry
2. **Configuration issues** - Check the ConfigMap for database connection settings:
   ```shell
   kubectl get configmap -n oracle-database-exporter
   kubectl describe configmap oracle-database-exporter-config -n oracle-database-exporter
   ```

3. **Secret missing** - Verify database credentials secret exists:
   ```shell
   kubectl get secret -n oracle-database-exporter
   ```

### Database connection errors

**Check exporter logs for connection errors:**

```shell
kubectl logs -n oracle-database-exporter -l app=oracle-database-exporter --tail=100
```

**Common connection errors:**

1. **"ORA-01017: invalid username/password"**
   - Verify database credentials in the secret:
     ```shell
     kubectl get secret <database-secret-name> -n oracle-database-exporter -o yaml
     ```
   - Ensure the database user has proper privileges:
     ```sql
     GRANT CREATE SESSION TO <exporter-user>;
     GRANT SELECT ON V_$SESSION TO <exporter-user>;
     GRANT SELECT ON V_$SESSTAT TO <exporter-user>;
     GRANT SELECT ON DBA_TABLESPACES TO <exporter-user>;
     ```

2. **"Connection refused" or timeout errors**
   - Verify database service is accessible:
     ```shell
     kubectl get svc | grep database
     ```
   - Test connectivity from exporter namespace:
     ```shell
     kubectl run test-db-connection --rm -it --restart=Never \
       --image=container-registry.oracle.com/database/sqlcl:25.3.0 \
       -n oracle-database-exporter \
       -- bash -c "nc -zv <database-service-name> 1521"
     ```

3. **"ORA-12154: TNS:could not resolve the connect identifier"**
   - Verify connection string format in configuration
   - Check that the database service name is correct

**Enable debug logging:**

Edit the exporter deployment to add debug flags:

```shell
kubectl edit deployment oracle-database-exporter -n oracle-database-exporter
```

Add environment variable:

```yaml
env:
- name: LOG_LEVEL
  value: "debug"
```
## Dashboards

### Oracle Database Grafana Dashboard

![Oracle Database Dashboard](images/exporter-running-against-basedb.png)

### Transactional Event Queue Grafana Dashboard

![Oracle Database Dashboard](images/txeventq-dashboard-v2.png)

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).