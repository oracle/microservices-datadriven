#!/usr/bin/env bash
set -euo pipefail

# Prepares an OKE cluster for the SigNoZ two-stage upgrade workflow.
# This script installs only the Kubernetes snapshot API CRDs documented by OKE
# and creates an explicit retained VolumeSnapshotClass for OCI Block Volume.
# OKE supplies the CSI snapshot implementation in its managed control plane.

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:-obaas}"
RELEASE_NAME="${RELEASE_NAME:-obaas}"
SNAPSHOT_CLASS_NAME="${SNAPSHOT_CLASS_NAME:-obaas-oci-bv-snapshot}"
SNAPSHOTTER_VERSION="${SNAPSHOTTER_VERSION:-v8.2.0}"
CHECK_ONLY=false

usage() {
  cat <<'EOF'
Usage: prepare-oke-volume-snapshots.sh [options]

Options:
  --namespace NAME          OBaaS namespace (default: obaas)
  --release NAME            OBaaS Helm release (default: obaas)
  --snapshot-class NAME     VolumeSnapshotClass to create or validate
                            (default: obaas-oci-bv-snapshot)
  --check-only              Validate without creating cluster resources
  -h, --help                Show this help

Environment overrides:
  KUBECTL, NAMESPACE, RELEASE_NAME, SNAPSHOT_CLASS_NAME, SNAPSHOTTER_VERSION
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
    --check-only)
      CHECK_ONLY=true
      shift
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

crd_base="https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd"
crds=(
  "snapshot.storage.k8s.io_volumesnapshotclasses.yaml"
  "snapshot.storage.k8s.io_volumesnapshotcontents.yaml"
  "snapshot.storage.k8s.io_volumesnapshots.yaml"
)

if [[ "${CHECK_ONLY}" == "false" ]]; then
  echo "Installing pinned snapshot API CRDs from external-snapshotter ${SNAPSHOTTER_VERSION}..."
  for crd in "${crds[@]}"; do
    kube apply -f "${crd_base}/${crd}"
  done
fi

for crd in \
  volumesnapshotclasses.snapshot.storage.k8s.io \
  volumesnapshotcontents.snapshot.storage.k8s.io \
  volumesnapshots.snapshot.storage.k8s.io; do
  kube get crd "${crd}" >/dev/null 2>&1 || fail "required CRD '${crd}' is not installed"
  kube wait --for=condition=Established "crd/${crd}" --timeout=2m >/dev/null
done

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
elif [[ "${CHECK_ONLY}" == "true" ]]; then
  fail "VolumeSnapshotClass '${SNAPSHOT_CLASS_NAME}' is not installed"
else
  echo "Creating retained OCI Block Volume snapshot class..."
  kube create -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ${SNAPSHOT_CLASS_NAME}
  labels:
    app.kubernetes.io/managed-by: obaas-snapshot-preflight
    obaas.oracle.com/signoz-upgrade: "true"
driver: blockvolume.csi.oraclecloud.com
parameters:
  backupType: full
deletionPolicy: Retain
EOF
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
