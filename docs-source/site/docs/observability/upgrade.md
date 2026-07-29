---
title: Upgrade SigNoZ
sidebar_position: 9
---

# Upgrade SigNoZ

SigNoZ recommends backing up configuration and persistent data before an
upgrade. Its ClickHouse upgrade guidance explains that ClickHouse updates its
on-disk format in place and that downgrades are not guaranteed. See the official
[SigNoZ ClickHouse 25.12.5 upgrade guide](https://signoz.io/docs/operate/migration/upgrade-0-131/)
and [standard upgrade guide](https://signoz.io/docs/operate/migration/upgrade-standard/).

OBaaS implements this recommendation with a guarded two-stage Helm upgrade.
Stage 1 creates retained Kubernetes CSI snapshots and upgrades ClickHouse.
Stage 2 upgrades SigNoZ and runs its telemetry migrations only after it verifies
the Stage 1 result.

## Why OBaaS targets SigNoZ 0.134.0

SigNoZ `0.134.0` is a security update:

- [CVE-2026-63094](https://www.cve.org/CVERecord?id=CVE-2026-63094)
  affects SigNoZ through `0.133.0`. It is an SSO open-redirect vulnerability
  that can expose session tokens on installations configured with Google OAuth,
  SAML, or OIDC. The fix is included in `0.134.0`.
- [CVE-2026-57956](https://www.cve.org/CVERecord?id=CVE-2026-57956)
  affects versions before `0.133.0`. It allows an authenticated user to access
  another organization's alert rules. That fix was introduced in `0.133.0` and
  is also present in `0.134.0`.

SigNoZ `0.134.0` also changes PromQL regex matching to use anchored Prometheus
semantics. For example, `label=~"api"` now matches only `api`, not
`api-server`. Review customer-created PromQL dashboards and alerts that use
`=~` or `!~`. Use `.*expression.*` for substring matching and
`expression.*` for prefix matching. The dashboards supplied by OBaaS have been
updated and validated for this behavior. See the
[SigNoZ 0.134.0 changelog](https://signoz.io/changelog/).

:::note
SigNoZ `0.134.0` has a known migration issue for installations that use
PostgreSQL as the SigNoZ metastore. The OBaaS chart does not enable that
optional PostgreSQL subchart. It uses the persistent SQLite metastore under
`/var/lib/signoz`, so the default OBaaS installation is not affected. If a
customer has explicitly enabled the SigNoZ PostgreSQL metastore, stop and
validate that configuration separately before upgrading.
:::

:::warning
Do not use `--atomic` for this upgrade. An automatic Helm rollback could attempt
to start an older ClickHouse version against storage whose on-disk format has
already been upgraded.
:::

## Choose an upgrade path

Use the **preserve historical data** path for production environments and
whenever users, dashboards, or historical telemetry must remain recoverable.
This path requires two Helm upgrade commands.

Use the **no protected recovery** path only when losing historical telemetry is
acceptable. It uses one Helm upgrade command and does not create a backup. It
does not intentionally erase existing data; data normally remains when the
in-place upgrade succeeds.

Fresh installations do not use either upgrade profile. Install the current
OBaaS chart normally.

### Installations already running SigNoZ 0.133.0

Do not run Stage 1 on an installation that has already completed the earlier
two-stage upgrade to SigNoZ `0.133.0` and ClickHouse `25.12.5`. The Stage 1
profile intentionally pins SigNoZ `0.113.0` while upgrading ClickHouse.

After confirming that a retained backup or provider snapshot is available,
upgrade `0.133.0` to `0.134.0` as a normal patch update:

```bash
cd helm/infra-charts
helm upgrade <app-release> ./obaas \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  --set signozUpgrade.stage=standard
```

Then perform the validation in
[Validate the completed upgrade](#6-validate-the-completed-upgrade).

## Preserve historical data

The following examples use an OBaaS source checkout because the target chart is
still in development. Run them from the repository root and replace all
placeholders with the release's existing values.

### 1. Verify and record the current environment

```bash
kubectl config current-context
helm status <app-release> -n <application-namespace>
kubectl get pods,pvc -n <application-namespace>

helm get values <app-release> -n <application-namespace> -o yaml \
  > /tmp/obaas-pre-signoz-upgrade-values.yaml
helm get manifest <app-release> -n <application-namespace> \
  > /tmp/obaas-pre-signoz-upgrade-manifest.yaml
```

Confirm that SigNoZ, ClickHouse, and ZooKeeper are healthy. Record an
identifiable historical telemetry time range so it can be checked after the
upgrade.

Use the same customer values files, database settings, secret names, image
settings, and other overrides for both stages. Later values files take
precedence, so the selected stage profile must be last, except for the OKE
overlay that follows the Stage 1 profile.

### 2. Prepare volume snapshots

#### OKE with OCI Block Volume

Prepare each OKE cluster once:

```bash
cd helm/infra-charts
./tools/prepare-oke-volume-snapshots.sh \
  --namespace <application-namespace> \
  --release <app-release>
```

The script installs pinned Kubernetes VolumeSnapshot CRDs, creates the
non-default `obaas-oci-bv-snapshot` class, and validates the SigNoZ, ClickHouse,
and ZooKeeper PVCs. The class uses the OCI Block Volume CSI driver, full
backups, and `deletionPolicy: Retain`.

Validate an already prepared cluster without changing it:

```bash
./tools/prepare-oke-volume-snapshots.sh \
  --namespace <application-namespace> \
  --release <app-release> \
  --check-only
```

Kubernetes VolumeSnapshots do not require the operator to enter a backup size.
OCI backs up each complete source Block Volume. Review the capacities of all
protected PVCs and verify that the tenancy's OCI Block Volume Backup service
limits and budget can accommodate them.

#### Other Kubernetes providers

Install the provider-supported Kubernetes snapshot CRDs, common snapshot
controller, CSI snapshot implementation, and `VolumeSnapshotClass`. Verify
that the class uses the same CSI driver as the SigNoZ PVCs.

Set the class in a customer values file:

```yaml
signozUpgrade:
  backup:
    volumeSnapshotClassName: <snapshot-class-name>
```

Do not use the OKE preparation script with a non-OCI storage driver.

### 3. Run Stage 1

For OKE, run:

```bash
helm upgrade <app-release> ./obaas \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  -f ./obaas/examples/values-signoz-0.134-stage1.yaml \
  -f ./obaas/examples/values-signoz-0.134-stage1-oke.yaml
```

For another Kubernetes provider, omit the OKE values file and supply the
provider's snapshot class through the customer values:

```bash
helm upgrade <app-release> ./obaas \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  -f ./obaas/examples/values-signoz-0.134-stage1.yaml
```

Stage 1:

1. Invalidates any earlier completion marker.
1. Creates retained snapshots for the SigNoZ, ClickHouse, and ZooKeeper PVCs.
1. Waits for every snapshot to become ready.
1. Upgrades ClickHouse to `25.12.5`.
1. Validates the running ClickHouse version and original PVC identities.
1. Records a completion marker for Stage 2.

Check the result:

```bash
kubectl get volumesnapshots -n <application-namespace>
./tools/diagnose-signoz-upgrade.sh \
  <application-namespace> <app-release>
```

Do not continue unless every snapshot reports `readyToUse: true`, ClickHouse is
healthy, and the diagnostics show a complete Stage 1 marker.

### 4. Verify that the ClickHouse backup can be restored

Prove that the newest ClickHouse snapshot can provision a new volume and that
the restored volume contains recognizable ClickHouse data:

```bash
NAMESPACE=<application-namespace> \
RELEASE_NAME=<app-release> \
./tools/validate-signoz-snapshot-restore.sh
```

This is a restore smoke test, not a production restore. It creates a temporary
PVC, mounts it read-only, and leaves it available for inspection. It never
mounts or changes the live ClickHouse PVC.

The restore PVC size is selected automatically from the snapshot's
`status.restoreSize`. Run the cleanup commands printed by the script after
inspection. Do not continue to Stage 2 if the restore test fails.

### 5. Run Stage 2

```bash
helm upgrade <app-release> ./obaas \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  -f ./obaas/examples/values-signoz-0.134-stage2.yaml
```

Before modifying workloads, the Stage 2 gate verifies the completion marker,
ClickHouse version, original PVC identities, and retained snapshots. It then:

1. Upgrades SigNoZ to `0.134.0`.
1. Upgrades the SigNoZ OpenTelemetry Collector to `0.144.6`.
1. Runs the official telemetry-store migrations.
1. Removes obsolete SigNoZ resources.
1. Runs the OBaaS SigNoZ login and dashboard setup.
1. Validates historical and newly ingested telemetry rows.

### 6. Validate the completed upgrade

```bash
kubectl get pods,jobs -n <application-namespace>
./tools/diagnose-signoz-upgrade.sh \
  <application-namespace> <app-release>
```

Confirm:

- SigNoZ is running `v0.134.0`.
- The SigNoZ collector is running `v0.144.6`.
- ClickHouse is running `25.12.5`.
- The telemetry-store migrator and SigNoZ setup Jobs completed.
- Existing users can sign in.
- Existing dashboards remain available.
- Telemetry from before Stage 1 is visible.
- New metrics, logs, and traces are ingested.

### 7. Retain or remove the backups

Stage 1 snapshots and their underlying provider backups are retained
independently of Helm and may incur storage charges. Keep them through the
customer's upgrade and rollback window.

For OKE, inventory both the Kubernetes objects and OCI backup handles:

```bash
kubectl get volumesnapshots -n <application-namespace>
kubectl get volumesnapshotcontents \
  -o custom-columns='NAME:.metadata.name,POLICY:.spec.deletionPolicy,HANDLE:.status.snapshotHandle'
```

Remove the Kubernetes snapshot resources and retained OCI Block Volume backups
only under the customer's backup-retention policy.

## Upgrade without protected historical data

When historical data does not require backup protection, use the normal
single-command upgrade:

```bash
cd helm/infra-charts
helm upgrade <app-release> ./obaas \
  -n <application-namespace> \
  --timeout 30m \
  -f <customer-values-file> \
  --set signozUpgrade.stage=standard
```

This upgrades ClickHouse, SigNoZ, and the collector and runs the telemetry
migrations without first creating snapshots. Existing data normally remains if
the in-place upgrade succeeds, but there is no snapshot-based recovery path if
it fails.

:::danger
Do not use `helm uninstall` merely to discard SigNoZ history. The OBaaS chart
can delete all PVCs in the application namespace during uninstall, including
PVCs that are not part of SigNoZ.
:::

## Troubleshooting

Collect read-only diagnostics at any point:

```bash
cd helm/infra-charts
./tools/diagnose-signoz-upgrade.sh \
  <application-namespace> <app-release>
```

Stage 2 deliberately stops before changing workloads when its marker, version,
PVC, or snapshot checks fail. Correct the reported condition; do not bypass the
gate by manually creating or editing its completion marker.
