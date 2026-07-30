#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -u

KUBECTL="${KUBECTL:-kubectl}"
HELM="${HELM:-helm}"
NAMESPACE="${NAMESPACE:-obaas}"
RELEASE_NAME="${RELEASE_NAME:-obaas}"

usage() {
  cat <<'EOF'
Usage: diagnose-signoz-upgrade.sh [namespace] [release]

Prints read-only Helm, PVC, CSI snapshot, marker, workload, event, and hook-log
state for the SigNoZ two-stage upgrade.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
NAMESPACE="${1:-${NAMESPACE}}"
RELEASE_NAME="${2:-${RELEASE_NAME}}"
MARKER_NAME="${MARKER_NAME:-$("${KUBECTL}" get secret -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-marker=true" \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null)}"

section() {
  printf '\n=== %s ===\n' "$1"
}

section "Context"
"${KUBECTL}" config current-context 2>&1 || true
"${KUBECTL}" version 2>&1 || true

section "Helm release"
"${HELM}" status "${RELEASE_NAME}" -n "${NAMESPACE}" 2>&1 || true
"${HELM}" history "${RELEASE_NAME}" -n "${NAMESPACE}" 2>&1 || true

section "SigNoZ workloads and images"
"${KUBECTL}" get pods -n "${NAMESPACE}" \
  -o custom-columns='NAME:.metadata.name,READY:.status.containerStatuses[*].ready,PHASE:.status.phase,IMAGES:.spec.containers[*].image' \
  2>&1 | grep -E 'NAME|signoz|clickhouse|zookeeper' || true

section "Persistent storage"
for pvc in $("${KUBECTL}" get pvc -n "${NAMESPACE}" -o name 2>/dev/null); do
  pvc_name="${pvc#*/}"
  pv="$("${KUBECTL}" get "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.volumeName}' 2>/dev/null)"
  storage_class="$("${KUBECTL}" get "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.storageClassName}' 2>/dev/null)"
  driver="$("${KUBECTL}" get pv "${pv}" -o jsonpath='{.spec.csi.driver}' 2>/dev/null)"
  handle="$("${KUBECTL}" get pv "${pv}" -o jsonpath='{.spec.csi.volumeHandle}' 2>/dev/null)"
  printf 'PVC=%s PV=%s StorageClass=%s Driver=%s Handle=%s\n' \
    "${pvc_name}" "${pv}" "${storage_class}" "${driver}" "${handle}"
done

section "Snapshot API and classes"
"${KUBECTL}" api-resources --api-group=snapshot.storage.k8s.io 2>&1 || true
"${KUBECTL}" get volumesnapshotclass.snapshot.storage.k8s.io \
  -o custom-columns='NAME:.metadata.name,DRIVER:.driver,POLICY:.deletionPolicy,BACKUP_TYPE:.parameters.backupType' \
  2>&1 || true

section "Stage 1 snapshots"
"${KUBECTL}" get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-snapshot=true" \
  -o custom-columns='NAME:.metadata.name,COMPONENT:.metadata.labels.obaas\.oracle\.com/component,SOURCE_PVC:.spec.source.persistentVolumeClaimName,READY:.status.readyToUse,CONTENT:.status.boundVolumeSnapshotContentName,ERROR:.status.error.message' \
  2>&1 || true

section "Snapshot contents and OCI backup handles"
"${KUBECTL}" get volumesnapshotcontent.snapshot.storage.k8s.io \
  -o custom-columns='NAME:.metadata.name,DRIVER:.spec.driver,POLICY:.spec.deletionPolicy,SNAPSHOT_HANDLE:.status.snapshotHandle,READY:.status.readyToUse,ERROR:.status.error.message' \
  2>&1 || true

section "Stage 1 completion marker"
if [[ -n "${MARKER_NAME}" ]] && \
  "${KUBECTL}" get secret "${MARKER_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  for key in workflow stage status releaseName namespace helmRevision targetVersion clickhouseVersion completedAt; do
    value="$("${KUBECTL}" get secret "${MARKER_NAME}" -n "${NAMESPACE}" \
      -o go-template="{{index .data \"${key}\" | base64decode}}" 2>/dev/null)"
    printf '%s=%s\n' "${key}" "${value}"
  done
else
  echo "No Stage 1 completion marker found for release '${RELEASE_NAME}'."
fi

section "Upgrade hook jobs and pods"
"${KUBECTL}" get jobs,pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" \
  --show-labels 2>&1 | grep -E 'NAME|signoz-(upgrade|stage2)' || true

section "Upgrade hook logs"
for selector in \
  signoz-upgrade-snapshot \
  signoz-upgrade-validation \
  signoz-stage2-gate \
  signoz-stage2-validation \
  signoz-upgrade-cleanup; do
  echo "--- ${selector} ---"
  "${KUBECTL}" logs -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${selector}" \
    --all-containers --tail=200 2>&1 || true
done

section "Recent namespace events"
"${KUBECTL}" get events -n "${NAMESPACE}" --sort-by=.lastTimestamp 2>&1 | tail -100 || true
