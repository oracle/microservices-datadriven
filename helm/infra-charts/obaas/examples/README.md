# OBaaS Helm Chart - Example Configurations

This directory contains example values files demonstrating different configuration scenarios for the OBaaS Helm chart.

## Available Examples

### 1. Default Configuration (`values-default.yaml`)

Minimal configuration with no overrides. Envoy Gateway is enabled by default, deprecated ingress-nginx is disabled by default, and all enabled subcharts deploy to the release namespace.

**Use case:** Quick start, development, testing

**Installation:**
```bash
helm upgrade --install obaas . -f examples/values-default.yaml -n obaas --create-namespace
```

### 2. Namespace and Scope Configuration (`values-namespace-override.yaml`)

Shows how to preserve legacy ingress-nginx scope settings for explicit opt-in installs. All obaas components deploy to the release namespace (specified with `-n` flag).

**Use case:** Controlling which namespaces components watch

**Installation:**
```bash
# Option 1: Let Helm create the namespace
helm upgrade --install obaas . -f examples/values-namespace-override.yaml -n obaas-platform --create-namespace

# Option 2: Create the namespace first
kubectl create namespace obaas-platform
helm upgrade --install obaas . -f examples/values-namespace-override.yaml -n obaas-platform
```

### 3. Multi-Tenant Setup (`values-tenant1.yaml`, `values-tenant2.yaml`)

Configure credentials for each tenant and preserve optional unique ingress-nginx settings for clusters that explicitly enable the deprecated Ingress API path.

**Use case:** Multi-tenant deployments, namespace isolation, multiple independent OBaaS instances

**When legacy ingress-nginx is enabled:**
- Each ingress-nginx controller creates a cluster-scoped `IngressClass` resource
- Multiple controllers must have unique IngressClass names to avoid conflicts
- Each controller needs unique election IDs to prevent leader election issues

**Installation:**
```bash
# Install first tenant
helm upgrade --install obaas-tenant1 . -n tenant1 -f examples/values-tenant1.yaml --create-namespace

# Install second tenant
helm upgrade --install obaas-tenant2 . -n tenant2 -f examples/values-tenant2.yaml --create-namespace
```

**Important:** When explicitly enabling ingress-nginx, always ensure each tenant has:
- Unique `controller.ingressClass` value
- Unique `controller.ingressClassResource.name` value
- Unique `controller.ingressClassResource.controllerValue`
- Unique `controller.electionID`

### 4. Existing ADB Configuration (`values-existing-adb.yaml`)

Configure OBaaS to use an existing OCI Autonomous Database (ADB-S) instead of deploying a database container.

**Use case:** Production deployments using a pre-provisioned OCI Autonomous Database

**Prerequisites:**
1. Obtain an OCI API Key and create the k8s configmap/secret:
```bash
python3 tools/oci_config.py --namespace NAMESPACE [--config CONFIG] [--profile PROFILE]
```

2. Create the privileged authentication secret for the ADMIN user:
```bash
kubectl -n NAMESPACE create secret generic db-priv-authn \
  --from-literal=username=ADMIN \
  --from-literal=password=<ADMIN PASSWORD> \
  --from-literal=service=<DBNAME>_TP
```

**Installation:**
```bash
helm upgrade --install obaas . \
  -n NAMESPACE \
  -f examples/values-existing-adb.yaml \
  --set database.oci.ocid=<ADB_OCID>
```

### 5. SIDB-FREE Database (`values-sidb-free.yaml`)

Example configuration for using Oracle Database Free as a container in the cluster. This is the default database type.

**Use case:** Development, testing, standalone deployments

**Installation:**
```bash
helm upgrade --install obaas . -f examples/values-sidb-free.yaml -n obaas --create-namespace
```

### 6. SigNoz Existing Secret (`values-signoz-existing-secret.yaml`)

Use a pre-existing Kubernetes secret for SigNoz admin authentication instead of auto-generating one.

**Use case:** GitOps workflows, pre-provisioned credentials

**Installation:**
```bash
# Create the secret first
kubectl create secret generic my-signoz-secret \
  --from-literal=email=admin@mydomain.com \
  --from-literal=password=my-secure-password \
  -n obaas

# Install with the example
helm upgrade --install obaas . -f examples/values-signoz-existing-secret.yaml -n obaas
```

### 7. Kafka Enabled Configuration (`values-kafka.yaml`)

Create a Strimzi-managed Kafka cluster in the OBaaS release namespace.

**Use case:** Kafka integration testing, CloudBank Helidon producer/consumer workloads, Kafka observability validation

**Prerequisites:**
1. Install `obaas-prereqs` once per cluster.
2. Keep `strimzi-kafka-operator` enabled in `obaas-prereqs`.
3. Ensure the Strimzi operator watches the OBaaS release namespace.

**Installation:**
```bash
helm upgrade --install obaas . \
  -f examples/values-kafka.yaml \
  -n obaas \
  --create-namespace
```

**Optional Kafka metrics in SigNoz:**
```bash
helm upgrade --install obaas . \
  -f examples/values-kafka.yaml \
  -f extensions/kafka-metrics.yaml \
  -n obaas \
  --create-namespace
```

With release name `obaas`, Kafka clients can use `obaas-kafka-cluster-kafka-bootstrap:9092`.
The chart also creates the stable alias `kafka-bootstrap:9092`.

### 8. Coherence Enabled Configuration (`values-coherence.yaml`)

Create a three-member Coherence cluster managed by the Coherence Operator in the OBaaS release namespace.

**Use case:** Coherence integration testing and development workloads that require a distributed cache or data grid

**Prerequisites:**
1. Install `obaas-prereqs` once per cluster.
2. Keep `coherence-operator` enabled in `obaas-prereqs`.
3. Ensure the Coherence Operator watches the OBaaS release namespace.

**Installation:**
```bash
helm upgrade --install obaas . \
  -f examples/values-coherence.yaml \
  -n obaas \
  --create-namespace
```

Set `coherence.name` to a DNS-compatible name unique within the release
namespace. This example uses `mysample-cluster`; replace it with the name for
your cluster. Verify it and its members with:

```bash
kubectl get coherence <coherence-cluster-name> -n obaas
kubectl get pods -n obaas
```

The example is ephemeral. Add `coherence.coherence.persistence` with a suitable
StorageClass and volume size when durable Coherence data is required.

### 9. Private Registry Configuration (`values-private-registry.yaml`)

Use a private container registry for all images with authentication.

**Use case:** Air-gapped environments, corporate registries, security compliance

**Prerequisites:**
1. Mirror all required images to your private registry
2. Create image pull secret:
```bash
kubectl create secret docker-registry myregistry-secret \
  --docker-server=myregistry.example.com \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>
```

**Installation:**
```bash
helm upgrade --install obaas . -f examples/values-private-registry.yaml
```

### 9. SigNoz 0.134.0 Two-Stage Upgrade Profiles

The files `values-signoz-0.134-stage1.yaml` and `values-signoz-0.134-stage2.yaml`
select the two steps of the planned SigNoz upgrade workflow. Always layer the
selected profile after the customer's normal values files and use the same Helm
release name and namespace for both commands.

SigNoz `0.134.0` adopts anchored Prometheus regex semantics for PromQL. Review
customer-created dashboard and alert matchers that relied on implicit substring
matching before upgrading.

Stage 1 creates and validates CSI snapshots, upgrades ClickHouse, and records a
completion marker. Stage 2 refuses to run without that validated marker, upgrades
SigNoz to `0.134.0` and the collector to `0.144.6`, runs the official telemetry
migrations, removes obsolete OIDC mock resources, reruns login/dashboard setup,
and validates historical plus newly ingested telemetry. Release validation
should cover both the full OKE upgrade and fresh-install paths.

OBaaS 2.0.0 includes SigNoz `0.102.1`, so its upgrade crosses the `0.113.0`
migrator replacement. OBaaS 2.1.0 already includes SigNoz `0.113.0` and has
completed that transition. The Stage 2 cleanup is unrelated to the migrator
replacement: it removes the OBaaS OIDC mock resources used by air-gapped 2.1.0
installations and does nothing when those resources are absent.

Stage 1 snapshots are retained independently of the Helm hook and may incur storage
charges. Helm does not delete them automatically.

#### OKE snapshot preparation

OKE uses the OCI Block Volume CSI driver to turn Kubernetes `VolumeSnapshot`
objects into OCI Block Volume backups. Prepare each OKE cluster once before its
first two-stage SigNoZ upgrade:

```bash
../tools/prepare-oke-volume-snapshots.sh \
  --namespace obaas \
  --release obaas
```

The script is idempotent. It installs a pinned version of the three Kubernetes
snapshot API CRDs, creates the non-default `obaas-oci-bv-snapshot` class with
`backupType: full` and `deletionPolicy: Retain`, and verifies that the SigNoZ,
ClickHouse, and ZooKeeper PVCs are backed by OCI Block Volume CSI PVs. It does
not install a generic snapshot controller because OKE supplies the snapshot
implementation through its managed control plane.

To validate an already prepared cluster without changing it:

```bash
../tools/prepare-oke-volume-snapshots.sh \
  --namespace obaas \
  --release obaas \
  --check-only
```

For another Kubernetes provider, install that provider's supported snapshot
CRDs, snapshot controller, CSI snapshot implementation, and
`VolumeSnapshotClass`. Then set
`signozUpgrade.backup.volumeSnapshotClassName` to that class. Do not use the OKE
preparation script for a non-OKE storage driver.

#### Upgrade commands

```bash
# Generic Stage 1 profile
helm upgrade obaas . \
  -n obaas \
  --timeout 30m \
  -f <customer-values-file> \
  -f examples/values-signoz-0.134-stage1.yaml

# OKE Stage 1 adds the explicit retained OCI snapshot class
helm upgrade obaas . \
  -n obaas \
  --timeout 30m \
  -f <customer-values-file> \
  -f examples/values-signoz-0.134-stage1.yaml \
  -f examples/values-signoz-0.134-stage1-oke.yaml

# Stage 2 profile (gate, SigNoz upgrade, cleanup, migrations, and validation)
helm upgrade obaas . \
  -n obaas \
  --timeout 30m \
  -f <customer-values-file> \
  -f examples/values-signoz-0.134-stage2.yaml
```

After Stage 1, verify that a retained backup can provision a new volume before
running Stage 2:

```bash
../tools/validate-signoz-snapshot-restore.sh
```

This restores the newest ClickHouse Stage 1 snapshot into a temporary PVC,
mounts it read-only, and checks for ClickHouse data. The restored PVC is retained
for inspection and the script prints explicit cleanup commands. This restored
volume incurs OCI Block Volume charges until it is deleted.

Collect read-only upgrade diagnostics at any point with:

```bash
../tools/diagnose-signoz-upgrade.sh obaas obaas
```

The report includes Helm history, workload images, PVC-to-volume OCID mappings,
snapshot readiness, OCI backup handles, the Stage 1 marker, hook logs, and recent
events. It does not print application or database credentials.

## Customizing Examples

You can combine examples or create your own custom values file:

```bash
# Combine multi-tenant and private registry configurations
helm upgrade --install obaas-tenant1 . \
  -f examples/values-tenant1.yaml \
  -f examples/values-private-registry.yaml \
  -n tenant1 --create-namespace
```

Or create a custom values file that extends an example:

```yaml
# my-custom-values.yaml
global:
  imagePullSecrets:
    - myregistry-secret

# Disable components you don't need
ai-optimizer:
  enabled: false

signoz:
  enabled: false
```

## Namespace Details

All obaas chart components deploy to the release namespace (specified with `-n` flag during install). There is no `global.namespace` override.

**Component Scopes:**
- **ingress-nginx** - Deprecated and disabled by default; when explicitly enabled, it watches only the release namespace (`scope.enabled: true`)

## Image Registry Override Details

Each subchart has its own image configuration that must be explicitly set for private registries.

### Subcharts with Separate Registry Field
These subcharts have a dedicated registry field (set to your registry URL):
- **ingress-nginx**: `controller.image.registry` when deprecated ingress-nginx is explicitly enabled
- **signoz**: `global.imageRegistry`
- **apisix etcd**: `apisix.etcd.image.registry`

### OBaaS Components Requiring Full Repository Path
These components require the full image path including registry in their `image.repository`:
- **eureka**, **admin-server**, **otmm**, **oracle-database-exporter**
- **database** (for SIDB-FREE/ADB-FREE)
- **apisix**: `apisix.image.repository`, `apisix.initContainer.image`

**Note:** Image pull secrets are propagated to subcharts via `global.imagePullSecrets`.

See `values-private-registry.yaml` for complete examples.

**Note:** Cluster-singleton prerequisites (cert-manager, external-secrets, metrics-server, kube-state-metrics, strimzi-kafka-operator, coherence-operator) have their own image configuration in the `obaas-prereqs` chart.

## More Information

For complete configuration options, see the main `values.yaml` file and individual subchart documentation.
