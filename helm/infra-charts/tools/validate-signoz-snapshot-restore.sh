#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE=""
RELEASE_NAME=""
COMPONENT="clickhouse"
TIMEOUT="15m"
CHECK_IMAGE="docker.io/busybox:1.37"

usage() {
  cat <<'EOF'
Usage: validate-signoz-snapshot-restore.sh --namespace NAME --release NAME [options]

Options:
  --namespace NAME          OBaaS namespace (required)
  --release NAME            OBaaS Helm release (required)
  --component NAME          Component to restore: clickhouse, signoz, or zookeeper
                            (default: clickhouse)
  --timeout DURATION        Restore validation timeout (default: 15m)
  --check-image IMAGE       Image used to inspect restored data
                            (default: docker.io/busybox:1.37)
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
    --component)
      [[ "$#" -ge 2 ]] || fail "--component requires a value"
      COMPONENT="$2"
      shift 2
      ;;
    --timeout)
      [[ "$#" -ge 2 ]] || fail "--timeout requires a value"
      TIMEOUT="$2"
      shift 2
      ;;
    --check-image)
      [[ "$#" -ge 2 ]] || fail "--check-image requires a value"
      CHECK_IMAGE="$2"
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

hash8() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | cut -c1-8
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | cut -c1-8
  else
    fail "sha256sum or shasum is required to generate a restore resource suffix"
  fi
}

case "${COMPONENT}" in
  clickhouse)
    content_check='test -d /restore/store -o -d /restore/data'
    ;;
  signoz)
    content_check='test -n "$(find /restore -mindepth 1 -maxdepth 2 -print -quit)"'
    ;;
  zookeeper)
    content_check='test -d /restore/data -o -d /restore/version-2 -o -n "$(find /restore -mindepth 1 -maxdepth 2 -print -quit)"'
    ;;
  *)
    fail "unsupported component '${COMPONENT}'"
    ;;
esac

snapshot="$(kube get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-snapshot=true,obaas.oracle.com/component=${COMPONENT}" \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
[[ -n "${snapshot}" ]] || fail "no Stage 1 snapshot found for component '${COMPONENT}'"

ready="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.status.readyToUse}')"
[[ "${ready}" == "true" ]] || fail "snapshot '${snapshot}' is not ready"

source_pvc="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" \
  -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc}')"
[[ -n "${source_pvc}" ]] || fail "snapshot '${snapshot}' has no recorded source PVC"
storage_class="$(kube get pvc "${source_pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.storageClassName}')"
size="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.restoreSize}')"
[[ -n "${size}" ]] || fail "snapshot '${snapshot}' does not report a restore size"
access_mode="$(kube get pvc "${source_pvc}" -n "${NAMESPACE}" -o jsonpath='{.spec.accessModes[0]}')"

suffix="$(hash8 "${snapshot}")"
restore_pvc="$(printf 'signoz-restore-%s-%s' "${COMPONENT}" "${suffix}" | cut -c1-63 | sed 's/-$//')"
check_pod="${restore_pvc}-check"

if kube get pvc "${restore_pvc}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  fail "restore PVC '${restore_pvc}' already exists; inspect or remove it before retrying"
fi

echo "Restoring snapshot '${snapshot}' into PVC '${restore_pvc}'..."
kube create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${restore_pvc}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/instance: ${RELEASE_NAME}
    obaas.oracle.com/signoz-restore-check: "true"
spec:
  storageClassName: ${storage_class}
  dataSource:
    name: ${snapshot}
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ${access_mode}
  resources:
    requests:
      storage: ${size}
EOF

# WaitForFirstConsumer storage classes bind only after a pod requests the PVC.
kube create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${check_pod}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/instance: ${RELEASE_NAME}
    obaas.oracle.com/signoz-restore-check: "true"
spec:
  restartPolicy: Never
  containers:
    - name: verify
      image: ${CHECK_IMAGE}
      command: ["/bin/sh", "-c"]
      args:
        - |
          set -eu
          ${content_check}
          echo "Restored ${COMPONENT} volume contains expected data."
          find /restore -mindepth 1 -maxdepth 2 -print | head -50
      volumeMounts:
        - name: restored-data
          mountPath: /restore
          readOnly: true
  volumes:
    - name: restored-data
      persistentVolumeClaim:
        claimName: ${restore_pvc}
EOF

kube wait pod "${check_pod}" -n "${NAMESPACE}" --for=jsonpath='{.status.phase}'=Succeeded --timeout="${TIMEOUT}" || {
  kube describe pod "${check_pod}" -n "${NAMESPACE}" || true
  kube logs "${check_pod}" -n "${NAMESPACE}" || true
  fail "restored volume content validation failed"
}
kube logs "${check_pod}" -n "${NAMESPACE}"

echo
echo "Snapshot restore validation passed."
echo "The restored PVC is intentionally retained for inspection:"
echo "  kubectl get pvc ${restore_pvc} -n ${NAMESPACE}"
echo "Remove the temporary restored volume after inspection:"
echo "  kubectl delete pod ${check_pod} -n ${NAMESPACE}"
echo "  kubectl delete pvc ${restore_pvc} -n ${NAMESPACE}"
