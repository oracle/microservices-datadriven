#!/bin/sh
set -eu

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:?NAMESPACE is required}"
RELEASE_NAME="${RELEASE_NAME:?RELEASE_NAME is required}"
RELEASE_REVISION="${RELEASE_REVISION:?RELEASE_REVISION is required}"
TARGET_VERSION="${TARGET_VERSION:?TARGET_VERSION is required}"
SNAPSHOT_TIMEOUT="${SNAPSHOT_TIMEOUT:?SNAPSHOT_TIMEOUT is required}"
MARKER_SECRET_NAME="${MARKER_SECRET_NAME:?MARKER_SECRET_NAME is required}"
SNAPSHOT_CLASS_NAME="${SNAPSHOT_CLASS_NAME:-}"
SNAPSHOT_CLASS_MAPPINGS="${SNAPSHOT_CLASS_MAPPINGS:-}"
TARGET_COMPONENTS="${TARGET_COMPONENTS:-signoz clickhouse zookeeper}"

kube() {
  "${KUBECTL}" "$@"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_snapshot_api() {
  resources="$(kube api-resources --api-group=snapshot.storage.k8s.io -o name 2>/dev/null || true)"
  for resource in volumesnapshots volumesnapshotclasses volumesnapshotcontents; do
    echo "${resources}" | grep -Eq "^${resource}(\\.snapshot\\.storage\\.k8s\\.io)?$" || \
      fail "Kubernetes snapshot API resource '${resource}.snapshot.storage.k8s.io' is not installed"
  done
}

discover_pvcs() {
  target_file="$1"
  : >"${target_file}"

  for component in ${TARGET_COMPONENTS}; do
    claims="$(kube get pods -n "${NAMESPACE}" \
      -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${component}" \
      -o jsonpath='{range .items[*]}{range .spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}{end}' \
      | sed '/^$/d' | sort -u)"

    [ -n "${claims}" ] || fail "No mounted PVC was found for required SigNoz component '${component}'"
    for pvc in ${claims}; do
      printf '%s\t%s\n' "${component}" "${pvc}" >>"${target_file}"
    done
  done

  sort -u "${target_file}" -o "${target_file}"
}

mapped_snapshot_class() {
  storage_class="$1"
  [ -n "${SNAPSHOT_CLASS_MAPPINGS}" ] || return 0
  printf '%s\n' "${SNAPSHOT_CLASS_MAPPINGS}" | awk -F '\t' -v storage_class="${storage_class}" \
    '$1 == storage_class { print $2; exit }'
}

default_snapshot_classes_for_driver() {
  csi_driver="$1"
  for resource in $(kube get volumesnapshotclasses.snapshot.storage.k8s.io -o name); do
    class_driver="$(kube get "${resource}" -o jsonpath='{.driver}')"
    [ "${class_driver}" = "${csi_driver}" ] || continue

    is_default="$(kube get "${resource}" \
      -o jsonpath='{.metadata.annotations.snapshot\.storage\.kubernetes\.io/is-default-class}')"
    if [ "${is_default}" != "true" ]; then
      is_default="$(kube get "${resource}" \
        -o jsonpath='{.metadata.annotations.snapshot\.storage\.k8s\.io/is-default-class}')"
    fi
    [ "${is_default}" = "true" ] && echo "${resource#*/}"
  done
}

select_snapshot_class() {
  storage_class="$1"
  csi_driver="$2"
  selected="${SNAPSHOT_CLASS_NAME}"

  if [ -z "${selected}" ]; then
    selected="$(mapped_snapshot_class "${storage_class}")"
  fi

  if [ -z "${selected}" ]; then
    defaults="$(default_snapshot_classes_for_driver "${csi_driver}")"
    default_count="$(printf '%s\n' "${defaults}" | sed '/^$/d' | wc -l | tr -d ' ')"
    [ "${default_count}" -gt 0 ] || \
      fail "No default VolumeSnapshotClass uses CSI driver '${csi_driver}' for StorageClass '${storage_class}'"
    [ "${default_count}" -eq 1 ] || \
      fail "Multiple default VolumeSnapshotClasses use CSI driver '${csi_driver}'; configure an explicit class"
    selected="${defaults}"
  fi

  kube get volumesnapshotclass.snapshot.storage.k8s.io "${selected}" >/dev/null 2>&1 || \
    fail "VolumeSnapshotClass '${selected}' does not exist"
  class_driver="$(kube get volumesnapshotclass.snapshot.storage.k8s.io "${selected}" -o jsonpath='{.driver}')"
  [ "${class_driver}" = "${csi_driver}" ] || \
    fail "VolumeSnapshotClass '${selected}' uses driver '${class_driver}', but StorageClass '${storage_class}' uses '${csi_driver}'"

  echo "${selected}"
}

create_snapshot() {
  component="$1"
  pvc="$2"
  batch="$3"

  phase="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')"
  [ "${phase}" = "Bound" ] || fail "PVC '${pvc}' is not Bound (phase: ${phase:-unknown})"

  pvc_uid="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.metadata.uid}')"
  storage_class="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.storageClassName}')"
  [ -n "${storage_class}" ] || fail "PVC '${pvc}' does not specify a CSI StorageClass"

  csi_driver="$(kube get storageclass "${storage_class}" -o jsonpath='{.provisioner}' 2>/dev/null || true)"
  [ -n "${csi_driver}" ] || fail "StorageClass '${storage_class}' does not exist or has no provisioner"
  kube get csidriver "${csi_driver}" >/dev/null 2>&1 || \
    fail "StorageClass '${storage_class}' uses '${csi_driver}', but no matching CSIDriver is installed"

  snapshot_class="$(select_snapshot_class "${storage_class}" "${csi_driver}")"
  pvc_prefix="$(printf '%.170s' "${pvc}")"
  target_version_name="$(printf '%s' "${TARGET_VERSION}" | tr '.' '-')"
  snapshot_name="${pvc_prefix}-signoz-${target_version_name}-r${RELEASE_REVISION}-${batch}"

  echo "Creating snapshot '${snapshot_name}' for ${component} PVC '${pvc}' using '${snapshot_class}'"
  kube create -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: ${snapshot_name}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/instance: ${RELEASE_NAME}
    app.kubernetes.io/managed-by: Helm
    obaas.oracle.com/signoz-upgrade-snapshot: "true"
    obaas.oracle.com/upgrade-target: "${TARGET_VERSION}"
    obaas.oracle.com/snapshot-batch: "${batch}"
    obaas.oracle.com/helm-revision: "${RELEASE_REVISION}"
    obaas.oracle.com/component: "${component}"
  annotations:
    helm.sh/resource-policy: keep
    obaas.oracle.com/source-pvc: "${pvc}"
    obaas.oracle.com/source-pvc-uid: "${pvc_uid}"
    obaas.oracle.com/source-storage-class: "${storage_class}"
    obaas.oracle.com/volume-snapshot-class: "${snapshot_class}"
spec:
  volumeSnapshotClassName: ${snapshot_class}
  source:
    persistentVolumeClaimName: ${pvc}
EOF
}

echo "=== SigNoz Stage 1 CSI snapshot hook ==="
echo "Invalidating any previous Stage 1 completion marker..."
kube delete secret "${MARKER_SECRET_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
require_snapshot_api

targets="$(mktemp)"
trap 'rm -f "${targets}"' EXIT
discover_pvcs "${targets}"

batch="$(date -u +%Y%m%d%H%M%S)"
while IFS="$(printf '\t')" read -r component pvc; do
  create_snapshot "${component}" "${pvc}" "${batch}"
done <"${targets}"

selector="app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-snapshot=true,obaas.oracle.com/snapshot-batch=${batch}"
echo "Waiting up to ${SNAPSHOT_TIMEOUT} for all snapshots in batch '${batch}' to become ready..."
if ! kube wait volumesnapshot.snapshot.storage.k8s.io \
  -n "${NAMESPACE}" \
  -l "${selector}" \
  --for=jsonpath='{.status.readyToUse}'=true \
  --timeout="${SNAPSHOT_TIMEOUT}"; then
  kube get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" -l "${selector}" || true
  fail "Timed out or failed while waiting for CSI snapshots in batch '${batch}'"
fi

kube get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" -l "${selector}"
echo "All SigNoz Stage 1 CSI snapshots are ready."
