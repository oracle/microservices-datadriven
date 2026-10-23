---
title: SigNoz resource profiles
sidebar_position: 6.1
---

These SigNoz sizing overlays provide example configurations to size the bundled SigNoz chart. Use them as starting allocations for workload assessment. 

<table>
  <thead>
    <tr>
      <th scope="col">Profile</th>
      <th scope="col">ClickHouse layout</th>
      <th scope="col">SigNoz collectors</th>
      <th scope="col">Metadata store</th>
      <th scope="col">Intended use</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row"><a href="https://github.com/oracle/microservices-datadriven/blob/main/helm/infra-charts/obaas/examples/values-signoz-small.yaml">Small</a></th>
      <td>1 shard, 1 replica</td>
      <td>1</td>
      <td>SQLite by default; PostgreSQL optional</td>
      <td>Evaluation</td>
    </tr>
    <tr>
      <th scope="row"><a href="https://github.com/oracle/microservices-datadriven/blob/main/helm/infra-charts/obaas/examples/values-signoz-medium.yaml">Medium</a></th>
      <td>1 shard, 1 replica</td>
      <td>1</td>
      <td>SQLite by default; PostgreSQL optional</td>
      <td>Custom deployment with larger vertical allocations</td>
    </tr>
    <tr>
      <th scope="row"><a href="https://github.com/oracle/microservices-datadriven/blob/main/helm/infra-charts/obaas/examples/values-signoz-distributed.yaml">Distributed</a></th>
      <td>2 shards, 1 replica per shard</td>
      <td>3</td>
      <td>SQLite by default; PostgreSQL optional</td>
      <td>Adaptation of the upstream Community resource reference</td>
    </tr>
  </tbody>
</table>

The distributed profile follows the component counts and CPU/memory allocations
in [SigNoz Community resource planning](https://signoz.io/docs/setup/capacity-planning/community/resources-planning/).
The example sets both requests and limits to the reference allocation for those
components. Small and medium provide lower resource starting points for OBaaS;
validate their suitability against your workload.

## Resource allocations

Each cell shows CPU cores / memory GiB, as **request → limit**, per instance.
Memory expressed in MiB in YAML is shown as fractional GiB here.

<table>
  <thead>
    <tr>
      <th scope="col">Component</th>
      <th scope="col">Small (Requests → Limits)</th>
      <th scope="col">Medium (Requests → Limits)</th>
      <th scope="col">Distributed (Requests → Limits)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">ClickHouse, per shard</th>
      <td>2 / 8 → 4 / 16</td>
      <td>4 / 16 → 8 / 32</td>
      <td>16 / 32 → 16 / 32</td>
    </tr>
    <tr>
      <th scope="row">SigNoz collector, each</th>
      <td>0.25 / 0.5 → 1 / 2</td>
      <td>1 / 2 → 2 / 4</td>
      <td>4 / 16 → 4 / 16</td>
    </tr>
    <tr>
      <th scope="row">SigNoz server</th>
      <td>0.25 / 0.5 → 1 / 1</td>
      <td>0.5 / 1 → 2 / 2</td>
      <td>4 / 8 → 4 / 8</td>
    </tr>
    <tr>
      <th scope="row">ZooKeeper, each</th>
      <td>0.25 / 2 → 1 / 4</td>
      <td>0.25 / 2 → 1 / 4</td>
      <td>2 / 8 → 2 / 8</td>
    </tr>
    <tr>
      <th scope="row">Node agent, per node</th>
      <td>0.1 / 0.25 → 0.5 / 0.5</td>
      <td>0.25 / 0.5 → 1 / 1</td>
      <td>0.25 / 0.5 → 1 / 1</td>
    </tr>
    <tr>
      <th scope="row">Cluster collector, singleton</th>
      <td>0.25 / 0.5 → 1 / 1</td>
      <td>0.5 / 1 → 2 / 2</td>
      <td>1 / 2 → 2 / 4</td>
    </tr>
  </tbody>
</table>

### Totals

These totals include all ClickHouse, SigNoz collector, SigNoz server and ZooKeeper
instances, the ClickHouse operator and its metrics exporter, and the singleton
cluster collector. Each cell shows **requests → limits**.

<table>
  <thead>
    <tr>
      <th scope="col">Profile</th>
      <th scope="col">CPU cores</th>
      <th scope="col">Memory (GiB)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Small</th>
      <td>3.2 → 9</td>
      <td>11.875 → 24.75</td>
    </tr>
    <tr>
      <th scope="row">Medium</th>
      <td>6.45 → 16</td>
      <td>22.375 → 44.75</td>
    </tr>
    <tr>
      <th scope="row">Distributed</th>
      <td>55.2 → 57</td>
      <td>146.375 → 148.75</td>
    </tr>
  </tbody>
</table>

## Configuring your cluster

Run from the repository root after preparing OBaaS prerequisites, database,
access, secrets and cluster capacity. Replace the release, namespace and values
placeholders with the settings for your installation.

```bash
helm lint helm/infra-charts/obaas \
  -f <environment-values.yaml> \
  -f helm/infra-charts/obaas/examples/values-signoz-small.yaml \
  -f <storage-and-site-overrides.yaml>

helm template <app-release> helm/infra-charts/obaas -n <application-namespace> \
  -f <environment-values.yaml> \
  -f helm/infra-charts/obaas/examples/values-signoz-small.yaml \
  -f <storage-and-site-overrides.yaml> > /tmp/obaas-rendered.yaml

helm install <app-release> helm/infra-charts/obaas \
  -n <application-namespace> --create-namespace \
  -f <environment-values.yaml> \
  -f helm/infra-charts/obaas/examples/values-signoz-small.yaml \
  -f <storage-and-site-overrides.yaml>
```

Substitute medium or distributed as appropriate. Inspect rendered files securely:
Later files override earlier ones, and YAML lists replace entire lists. Merge custom receivers, processors and RBAC deliberately.

## Storage, retention and buffering

Illustrative ClickHouse PVC capacities are 200Gi (small), 500Gi (medium) and 1Ti
**per shard** (distributed). ZooKeeper uses 20Gi per instance. SQLite, when used,
has 10Gi. Select storage
classes, volume performance and capacity in an overlay. For example:

```yaml
signoz:
  clickhouse:
    persistence:
      storageClass: <clickhouse-storage-class>
      size: <measured-capacity-per-instance>
    zookeeper:
      persistence:
        storageClass: <zookeeper-storage-class>
  signoz:
    persistence:
      storageClass: <metadata-storage-class>
```

Use measured compressed storage growth across telemetry and dependent tables,
desired retention, shard distribution and replication to estimate capacity.
Allow additional room for merges, diagnostics, delayed TTL cleanup and recovery.
Separate PVCs on the same exhausted backing filesystem do not isolate failures.
Shrinking PVCs is not a supported way to move down a size profile.

The included diagnostic TTL settings do not configure application retention.
Choose application logs, traces and metrics retention independently (for example,
2, 7 or 15 days) using the version-appropriate
[SigNoz retention controls](https://signoz.io/docs/userguide/retention-period/).
Verify dependent-table TTLs, existing-data behavior and disk reclamation before
claiming that a retention policy bounds storage.

The collector memory limiter is first in each signal pipeline and batch sizes are
bounded. Memory limiting can refuse telemetry; SDK/agent retries can expire.
Exporter queues and retries retain chart defaults. These examples do not add
persistent queue storage or promise restart-surviving buffering. For small or
medium, the optional [persistent queue overlay](https://oracle.github.io/microservices-backend/obaas/docs/observability/signoz-persistent-queue)
provides a dedicated PVC for a single collector. Distributed per-replica storage,
outage duration and disk capacity need a separate design and recovery test. See the
[OpenTelemetry exporter guidance](https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.144.0/exporter/exporterhelper/README.md).

## Existing releases and validation

These examples describe fresh installations. Before
changing an existing release, preserve its effective values, inventory versions
and topology, back up telemetry and metadata, and test restoration. Establish
data placement, distributed query coverage, schema compatibility, downtime and
recovery before changing shards or replicas. Enabling PostgreSQL does not copy
SQLite metadata. A Helm rollback alone does not reverse database migrations.
Review the [OBaaS upgrade guidance](https://oracle.github.io/microservices-backend/obaas/docs/observability/upgrade/)
and the upstream procedures for the installed versions.

Helm linting and rendering validate chart compatibility only. Before using a
profile operationally, measure sustained/burst ingestion with representative
payloads, cardinality and concurrent queries; reconcile generated and queryable
telemetry; measure freshness, queue drainage, memory peaks, throttling, query
latency and disk growth. Exercise backend slowdown, collector restart, disk
pressure and recovery. Use those measurements to choose resources, storage and
operational targets for your environment. Kafka is separate and is not enabled
by these overlays.
