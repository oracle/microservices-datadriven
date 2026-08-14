#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

# Validates an OKE cluster for the SigNoZ two-stage upgrade workflow.
# Cluster-wide snapshot APIs and classes must be installed by the cluster
# administrator before this script is run.

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE=""
RELEASE_NAME=""
SNAPSHOT_CLASS_NAME="obaas-oci-bv-snapshot"
OKE_SNAPSHOT_DOCUMENTATION="https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim_topic-Provisioning_PVCs_on_BV.htm"

usage() {
  cat <<'EOF'
Usage: prepare-oke-volume-snapshots.sh --namespace NAME --release NAME [options]

Options:
  --namespace NAME          OBaaS namespace (required)
  --release NAME            OBaaS Helm release (required)
  --snapshot-class NAME     VolumeSnapshotClass to validate
                            (default: obaas-oci-bv-snapshot)
  -h, --help                Show this help

Environment overrides:
  KUBECTL
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

kube() {
  "${KUBECTL}" "$@"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --namespace)
      [[ "$#" -ge 2 ]] || fail "--namespace requires a value"
      NAMESPACE="$2"
      shift 2
      ;;
    --release)
      [[ "$#" -ge 2 ]] || fail "--release requires a value"
      RELEASE_NAME="$2"
      shift 2
      ;;
    --snapshot-class)
      [[ "$#" -ge 2 ]] || fail "--snapshot-class requires a value"
      SNAPSHOT_CLASS_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

[[ -n "${NAMESPACE}" ]] || fail "--namespace is required"
[[ -n "${RELEASE_NAME}" ]] || fail "--release is required"

for command in "${KUBECTL}" grep sed sort; do
  command -v "${command}" >/dev/null 2>&1 || fail "required command not found: ${command}"
done

case "${SNAPSHOT_CLASS_NAME}" in
  ""|*[!a-z0-9.-]*|.*|*.) fail "invalid VolumeSnapshotClass name: ${SNAPSHOT_CLASS_NAME}" ;;
esac

echo "=== OKE VolumeSnapshot preparation ==="
echo "Kubernetes context: $(kube config current-context)"
echo "OBaaS release: ${NAMESPACE}/${RELEASE_NAME}"
echo "Snapshot class: ${SNAPSHOT_CLASS_NAME}"

for crd in \
  volumesnapshotclasses.snapshot.storage.k8s.io \
  volumesnapshotcontents.snapshot.storage.k8s.io \
  volumesnapshots.snapshot.storage.k8s.io; do
  kube get crd "${crd}" >/dev/null 2>&1 || \
    fail "required CRD '${crd}' is not installed. Ask the cluster administrator to configure OKE VolumeSnapshot support: ${OKE_SNAPSHOT_DOCUMENTATION}"
  kube wait --for=condition=Established "crd/${crd}" --timeout=2m >/dev/null
done

kube get csidriver blockvolume.csi.oraclecloud.com >/dev/null 2>&1 || \
  fail "required OKE CSI driver 'blockvolume.csi.oraclecloud.com' is not installed"

if kube get volumesnapshotclass.snapshot.storage.k8s.io "${SNAPSHOT_CLASS_NAME}" >/dev/null 2>&1; then
  class_driver="$(kube get volumesnapshotclass.snapshot.storage.k8s.io "${SNAPSHOT_CLASS_NAME}" -o jsonpath='{.driver}')"
  deletion_policy="$(kube get volumesnapshotclass.snapshot.storage.k8s.io "${SNAPSHOT_CLASS_NAME}" -o jsonpath='{.deletionPolicy}')"
  backup_type="$(kube get volumesnapshotclass.snapshot.storage.k8s.io "${SNAPSHOT_CLASS_NAME}" -o jsonpath='{.parameters.backupType}')"
  [[ "${class_driver}" == "blockvolume.csi.oraclecloud.com" ]] || \
    fail "VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' uses driver '${class_driver}'"
  [[ "${deletion_policy}" == "Retain" ]] || \
    fail "VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' must use deletionPolicy Retain"
  [[ "${backup_type}" == "full" ]] || \
    fail "VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' must use backupType full"
  echo "Existing VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' is compatible."
else
  fail "VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' is not installed. Ask the cluster administrator to create a retained, full-backup class for 'blockvolume.csi.oraclecloud.com': ${OKE_SNAPSHOT_DOCUMENTATION}"
fi

targets="$(mktemp)"
trap 'rm -f "${targets}"' EXIT
: >"${targets}"

for component in signoz clickhouse zookeeper; do
  claims="$(kube get pods -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${component}" \
    -o jsonpath='{range .items[*]}{range .spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}{end}' \
    | sed '/^$/d' | sort -u)"
  [[ -n "${claims}" ]] || fail "no mounted PVC found for required component '${component}'"
  while IFS= read -r pvc; do
    [[ -n "${pvc}" ]] && printf '%s\t%s\n' "${component}" "${pvc}" >>"${targets}"
  done <<<"${claims}"
done

while IFS=$'\t' read -r component pvc; do
  phase="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')"
  [[ "${phase}" == "Bound" ]] || fail "PVC '${pvc}' is not Bound"
  storage_class="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.storageClassName}')"
  provisioner="$(kube get storageclass "${storage_class}" -o jsonpath='{.provisioner}')"
  [[ "${provisioner}" == "blockvolume.csi.oraclecloud.com" ]] || \
    fail "PVC '${pvc}' uses non-OKE provisioner '${provisioner}'"
  pv="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.volumeName}')"
  pv_driver="$(kube get pv "${pv}" -o jsonpath='{.spec.csi.driver}')"
  [[ "${pv_driver}" == "${provisioner}" ]] || \
    fail "PV '${pv}' driver '${pv_driver}' does not match StorageClass provisioner '${provisioner}'"
  volume_handle="$(kube get pv "${pv}" -o jsonpath='{.spec.csi.volumeHandle}')"
  [[ "${volume_handle}" == ocid1.volume.* ]] || \
    fail "PV '${pv}' does not expose an OCI Block Volume OCID"
  printf 'Validated %-10s PVC=%s PV=%s\n' "${component}" "${pvc}" "${pv}"
done <"${targets}"

echo
echo "OKE snapshot prerequisites are ready."
echo "Use this Stage 1 value:"
echo "  --set signozUpgrade.backup.volumeSnapshotClassName=${SNAPSHOT_CLASS_NAME}"
