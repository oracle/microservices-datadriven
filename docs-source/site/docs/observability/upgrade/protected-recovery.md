---
title: Upgrade with protected recovery
sidebar_position: 1
---

# Upgrade to SigNoZ 0.134.0 with protected recovery

This is the recommended upgrade procedure. It uses two Helm commands. Stage 1
creates retained Kubernetes CSI snapshots and upgrades ClickHouse. Stage 2
upgrades SigNoZ and runs its telemetry migrations only after validating the
Stage 1 result.

## When to use this guide

Use this guide for production environments and whenever historical telemetry,
dashboards, users, or ClickHouse data must remain recoverable.

## Prerequisites

Add and update the released OBaaS Helm repository:

```bash
helm repo add obaas https://oracle.github.io/microservices-backend/helm
helm repo update
```

Confirm that:

- The existing release uses SigNoZ, ClickHouse, and ZooKeeper persistent
  volumes.
- The storage CSI driver supports Kubernetes `VolumeSnapshot` resources.
- A compatible `VolumeSnapshotClass` exists or can be created.
- Provider backup limits and budget can accommodate complete snapshots of all
  protected volumes.
- The same customer values, database settings, secret names, image settings,
  and other overrides are available for both stages.

Download the versioned OBaaS helper scripts. A source checkout is not required:

```bash
mkdir -p /tmp/obaas-signoz-upgrade

curl --fail --location \
  --output /tmp/obaas-signoz-upgrade/prepare-oke-volume-snapshots.sh \
  https://raw.githubusercontent.com/oracle/microservices-backend/OBAAS-2.1.1/helm/infra-charts/tools/prepare-oke-volume-snapshots.sh
curl --fail --location \
  --output /tmp/obaas-signoz-upgrade/validate-signoz-snapshot-restore.sh \
  https://raw.githubusercontent.com/oracle/microservices-backend/OBAAS-2.1.1/helm/infra-charts/tools/validate-signoz-snapshot-restore.sh
curl --fail --location \
  --output /tmp/obaas-signoz-upgrade/validate-signoz-upgrade.sh \
  https://raw.githubusercontent.com/oracle/microservices-backend/OBAAS-2.1.1/helm/infra-charts/tools/validate-signoz-upgrade.sh
curl --fail --location \
  --output /tmp/obaas-signoz-upgrade/collect-signoz-upgrade-diagnostics.sh \
  https://raw.githubusercontent.com/oracle/microservices-backend/OBAAS-2.1.1/helm/infra-charts/tools/collect-signoz-upgrade-diagnostics.sh

chmod +x /tmp/obaas-signoz-upgrade/*.sh
```

Replace all placeholders in the following commands with values for the existing
release.

## Step-by-step procedure

### 1. Record the current environment

```bash
kubectl config current-context
helm status <app-release> -n <application-namespace>
kubectl get pods,pvc -n <application-namespace>

helm get values <app-release> -n <application-namespace> -o yaml \
  > /tmp/obaas-pre-signoz-upgrade-values.yaml
helm get manifest <app-release> -n <application-namespace> \
  > /tmp/obaas-pre-signoz-upgrade-manifest.yaml
```

Wait for the stateful workloads and ClickHouse pods to report ready:

```bash
kubectl rollout status statefulset/<app-release>-signoz \
  -n <application-namespace> --timeout=5m
kubectl rollout status statefulset/<app-release>-zookeeper \
  -n <application-namespace> --timeout=5m
kubectl wait --for=condition=Ready pod \
  -l clickhouse.altinity.com/chi=<app-release>-clickhouse \
  -n <application-namespace> --timeout=5m
```

Inspect the component pods, persistent volumes, restart counts, and recent
warning events:

```bash
kubectl get pods,pvc -n <application-namespace> \
  | grep -E 'signoz|clickhouse|zookeeper'
kubectl get events -n <application-namespace> \
  --field-selector type=Warning \
  --sort-by=.lastTimestamp
```

Confirm that all listed pods are `Running` and fully ready, all listed PVCs are
`Bound`, and no component is repeatedly restarting. Investigate unresolved
warning events before continuing.

Verify the SigNoZ health endpoint. In one terminal, run:

```bash
kubectl port-forward -n <application-namespace> \
  service/<app-release>-signoz 18080:8080
```

While the port-forward is running, use another terminal to run:

```bash
curl --fail 'http://127.0.0.1:18080/api/v1/health?live=1'
```

Stop the port-forward after the health request succeeds. Log in to SigNoZ and
select an existing service with historical telemetry. Record the service name,
signal type, and a time range containing data so that the same telemetry can be
verified after Stage 2.

### 2. Prepare volume snapshots

#### OKE with OCI Block Volume

Check whether the Kubernetes VolumeSnapshot CRDs are installed:

```bash
kubectl get crd volumesnapshotclasses.snapshot.storage.k8s.io
kubectl get crd volumesnapshotcontents.snapshot.storage.k8s.io
kubectl get crd volumesnapshots.snapshot.storage.k8s.io
```

If any CRD is missing, a cluster administrator must install the CRDs using the
OKE-supported procedure:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.6.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.6.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.6.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
```

Verify that all three CRDs are available before continuing:

```bash
kubectl get crd | grep snapshot.storage.k8s.io
```

Creating cluster-wide CRDs requires cluster-administrator permissions. If the
CRDs are missing, attempting to create a `VolumeSnapshotClass` fails with `no
matches for kind "VolumeSnapshotClass" in version
"snapshot.storage.k8s.io/v1"`.

After the CRDs are installed, create a
`VolumeSnapshotClass` named `obaas-oci-bv-snapshot` with the following
settings:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: obaas-oci-bv-snapshot
driver: blockvolume.csi.oraclecloud.com
parameters:
  backupType: full
deletionPolicy: Retain
```

Follow the
[OKE volume snapshot prerequisites](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim_topic-Provisioning_PVCs_on_BV.htm)
to install the provider-supported snapshot APIs. Snapshot infrastructure is a
cluster-level prerequisite and is not installed by OBaaS upgrade tooling.

Validate the prepared OKE cluster:

```bash
/tmp/obaas-signoz-upgrade/prepare-oke-volume-snapshots.sh \
  --namespace <application-namespace> \
  --release <app-release>
```

The script performs read-only validation of the snapshot CRDs, OKE CSI driver,
snapshot class, and the SigNoZ, ClickHouse, and ZooKeeper PVCs. It fails with
corrective guidance when a required cluster resource is missing or
incompatible.

Kubernetes VolumeSnapshots do not require a backup size. OCI backs up each
complete source Block Volume. Review the protected PVC capacities and verify
that OCI Block Volume Backup service limits and budget can accommodate them.

#### Other Kubernetes providers

Install the provider-supported snapshot CRDs, common snapshot controller, CSI
snapshot implementation, and `VolumeSnapshotClass`. Verify that the snapshot
class uses the same CSI driver as the SigNoZ PVCs. Do not use the OKE
preparation script with a non-OCI storage driver.

### 3. Run Stage 1

For OKE:

```bash
helm upgrade <app-release> obaas/obaas \
  --version 0.1.1 \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  --set signozUpgrade.stage=stage1 \
  --set signozUpgrade.backup.volumeSnapshotClassName=obaas-oci-bv-snapshot \
  --set signoz.signoz.image.tag=v0.113.0 \
  --set signoz.otelCollector.image.tag=v0.144.1 \
  --set signoz.telemetryStoreMigrator.enabled=false \
  --set signoz.clickhouse.image.tag=25.12.5
```

For another Kubernetes provider:

```bash
helm upgrade <app-release> obaas/obaas \
  --version 0.1.1 \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  --set signozUpgrade.stage=stage1 \
  --set signozUpgrade.backup.volumeSnapshotClassName=<snapshot-class-name> \
  --set signoz.signoz.image.tag=v0.113.0 \
  --set signoz.otelCollector.image.tag=v0.144.1 \
  --set signoz.telemetryStoreMigrator.enabled=false \
  --set signoz.clickhouse.image.tag=25.12.5
```

Stage 1:

1. Invalidates any earlier completion marker.
2. Creates retained snapshots for the SigNoZ, ClickHouse, and ZooKeeper PVCs.
3. Waits for every snapshot to become ready.
4. Upgrades ClickHouse to `25.12.5`.
5. Validates the running ClickHouse version and original PVC identities.
6. Records a completion marker for Stage 2.

Do not continue until Stage 1 validation passes:

```bash
/tmp/obaas-signoz-upgrade/validate-signoz-upgrade.sh \
  --namespace <application-namespace> \
  --release <app-release> \
  --stage stage1
```

The command prints a short PASS/FAIL summary and returns a nonzero status if the
completion marker, snapshots, PVC identities, ClickHouse readiness, or
ClickHouse version is invalid. Stage 2 may be run only after it reports
`Stage 1 validation PASSED`.

### 4. Validate the ClickHouse restore point

Prove that the newest ClickHouse snapshot can provision a new volume and that
the restored volume contains recognizable ClickHouse data:

```bash
/tmp/obaas-signoz-upgrade/validate-signoz-snapshot-restore.sh \
  --namespace <application-namespace> \
  --release <app-release>
```

This smoke test creates a temporary PVC, mounts it read-only, and retains it for
inspection. It does not mount or change the live ClickHouse PVC. The restore
PVC size is selected automatically from the snapshot's `status.restoreSize`.
Run the cleanup commands printed by the script after inspection.

Do not continue to Stage 2 if restore validation fails.

### 5. Run Stage 2

Stage 1 uses temporary compatibility values that keep SigNoZ and its collector
at their pre-migration versions. Do not repeat those Stage 1 values and do not
use Helm's `--reuse-values` option. Run Stage 2 with the complete customer
values file and the explicit Stage 2 values shown below:

```bash
helm upgrade <app-release> obaas/obaas \
  --version 0.1.1 \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  --set signozUpgrade.stage=stage2 \
  --set signoz.signoz.image.tag=v0.134.0 \
  --set signoz.otelCollector.image.tag=v0.144.6 \
  --set signoz.telemetryStoreMigrator.enabled=true \
  --set signoz.clickhouse.image.tag=25.12.5
```

Before modifying workloads, the Stage 2 gate verifies the completion marker,
ClickHouse version, original PVC identities, and retained snapshots. It then
upgrades SigNoZ and the collector, runs telemetry migrations, removes obsolete
resources, runs the OBaaS SigNoZ setup, and validates historical and newly
ingested telemetry rows.

## Validation

```bash
/tmp/obaas-signoz-upgrade/validate-signoz-upgrade.sh \
  --namespace <application-namespace> \
  --release <app-release> \
  --stage stage2
```

The command returns a nonzero status unless the retained Stage 1 recovery
point, ClickHouse, SigNoZ, collector, migration Job, and setup Job are valid.

Confirm:

- SigNoZ is running `v0.134.0`.
- The SigNoZ collector is running `v0.144.6`.
- ClickHouse is running `25.12.5`.
- The telemetry-store migrator and SigNoZ setup Jobs completed.
- Existing users can sign in.
- Existing dashboards remain available.
- Telemetry from before Stage 1 is visible.
- New metrics, logs, and traces are ingested.

Keep the Stage 1 snapshots through the customer's upgrade and recovery window.
They are retained independently of Helm and may incur storage charges.

For OKE, inventory both Kubernetes objects and OCI backup handles:

```bash
kubectl get volumesnapshots -n <application-namespace>
kubectl get volumesnapshotcontents \
  -o custom-columns='NAME:.metadata.name,POLICY:.spec.deletionPolicy,HANDLE:.status.snapshotHandle'
```

Remove snapshots and retained provider backups only under the customer's backup
retention policy.

## Rollback and recovery

ClickHouse upgrades its on-disk format in place, so an automatic downgrade is
not guaranteed. Do not start an older ClickHouse version against the upgraded
live PVC.

If Stage 1 or Stage 2 fails:

1. Stop and retain the live PVCs, VolumeSnapshots, and provider backup handles.
2. Do not continue to Stage 2 when the Stage 1 marker or restore validation is
   incomplete.
3. Collect the diagnostics described below.
4. Follow the storage provider's procedure to create replacement volumes from
   the retained snapshots. OKE restores a snapshot into a new Block Volume; it
   does not revert an existing PVC in place.
5. Validate restored data before reconnecting workloads.

The chart does not automatically replace live PVCs during recovery. Preserve
the original resources and contact Oracle Support before rebinding restored
volumes in a production environment.

## Troubleshooting

If validation or either Helm stage fails, collect detailed read-only
troubleshooting data for Oracle Support:

```bash
/tmp/obaas-signoz-upgrade/collect-signoz-upgrade-diagnostics.sh \
  --namespace <application-namespace> \
  --release <app-release> \
  >signoz-upgrade-diagnostics.txt 2>&1
```

The file can contain workload logs. Review it before sharing it. Provider
volume and snapshot handles are omitted by default; add `--include-identifiers`
only when Oracle Support requests them.

Stage 2 stops before changing workloads when its marker, version, PVC, or
snapshot checks fail. Correct the reported condition; do not bypass the gate by
manually creating or editing the completion marker.
