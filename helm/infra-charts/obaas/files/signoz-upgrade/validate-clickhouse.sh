#!/bin/sh
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -eu

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:?NAMESPACE is required}"
RELEASE_NAME="${RELEASE_NAME:?RELEASE_NAME is required}"
RELEASE_REVISION="${RELEASE_REVISION:?RELEASE_REVISION is required}"
TARGET_VERSION="${TARGET_VERSION:?TARGET_VERSION is required}"
CLICKHOUSE_VERSION="${CLICKHOUSE_VERSION:?CLICKHOUSE_VERSION is required}"
VALIDATION_TIMEOUT="${VALIDATION_TIMEOUT:?VALIDATION_TIMEOUT is required}"
VALIDATION_POLL_INTERVAL="${VALIDATION_POLL_INTERVAL:-5}"
MARKER_SECRET_NAME="${MARKER_SECRET_NAME:?MARKER_SECRET_NAME is required}"

kube() { "${KUBECTL}" "$@"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

duration_seconds() {
  duration="$1"
  case "${duration}" in
    *s) value="${duration%s}"; multiplier=1 ;;
    *m) value="${duration%m}"; multiplier=60 ;;
    *h) value="${duration%h}"; multiplier=3600 ;;
    *) value="${duration}"; multiplier=1 ;;
  esac
  case "${value}" in
    ''|*[!0-9]*) fail "Invalid validation timeout '${duration}'" ;;
  esac
  echo $((value * multiplier))
}

component_pvcs() {
  component="$1"
  kube get pods -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${component}" \
    -o jsonpath='{range .items[*]}{range .spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}{end}' \
    | sed '/^$/d' | sort -u
}

echo "=== Validating SigNoz Stage 1 ==="

for component in signoz zookeeper; do
  kube wait pod -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${component}" \
    --for=condition=Ready --timeout="${VALIDATION_TIMEOUT}" || \
    fail "${component} pods did not become Ready"
done

chi_name="$(kube get clickhouseinstallations.clickhouse.altinity.com -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[0].metadata.name}')"
[ -n "${chi_name}" ] || fail "No ClickHouseInstallation was found"
clickhouse_password="$(kube get clickhouseinstallation.clickhouse.altinity.com "${chi_name}" -n "${NAMESPACE}" \
  -o jsonpath="{.spec.configuration.users['admin/password']}")"

timeout_seconds="$(duration_seconds "${VALIDATION_TIMEOUT}")"
deadline=$(( $(date +%s) + timeout_seconds ))
clickhouse_pod=""
clickhouse_image="<none>"
reported_version="<not queried>"

echo "Waiting up to ${VALIDATION_TIMEOUT} for ClickHouse ${CLICKHOUSE_VERSION} to become Ready..."
while :; do
  clickhouse_pod="$(kube get pods -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

  if [ -n "${clickhouse_pod}" ]; then
    clickhouse_image="$(kube get pod "${clickhouse_pod}" -n "${NAMESPACE}" \
      -o jsonpath='{.spec.containers[?(@.name=="clickhouse")].image}' 2>/dev/null || true)"
    case "${clickhouse_image}" in
      *:"${CLICKHOUSE_VERSION}"|*:"${CLICKHOUSE_VERSION}"@sha256:*)
        if kube wait pod "${clickhouse_pod}" -n "${NAMESPACE}" \
          --for=condition=Ready --timeout="${VALIDATION_TIMEOUT}" >/dev/null 2>&1; then
          if reported_version="$(kube exec -n "${NAMESPACE}" "${clickhouse_pod}" -c clickhouse -- \
            clickhouse-client --user admin --password "${clickhouse_password}" \
            --query 'SELECT version()' 2>/dev/null)"; then
            case "${reported_version}" in
              "${CLICKHOUSE_VERSION}"*) break ;;
            esac
          else
            reported_version="<query failed>"
          fi
        fi
        ;;
    esac
  fi

  if [ "$(date +%s)" -ge "${deadline}" ]; then
    fail "ClickHouse did not reach target ${CLICKHOUSE_VERSION} within ${VALIDATION_TIMEOUT}; last pod '${clickhouse_pod:-<none>}', image '${clickhouse_image:-<none>}', reported version '${reported_version:-<not queried>}'"
  fi
  sleep "${VALIDATION_POLL_INTERVAL}"
done

telemetry_rows="$(kube exec -n "${NAMESPACE}" "${clickhouse_pod}" -c clickhouse -- \
  clickhouse-client --user admin --password "${clickhouse_password}" \
  --query "SELECT toString(sum(rows)) FROM system.parts WHERE active AND startsWith(database, 'signoz_')")"
case "${telemetry_rows}" in ''|*[!0-9]*) fail "Unable to record the historical telemetry row count" ;; esac

snapshot_selector="app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-snapshot=true,obaas.oracle.com/helm-revision=${RELEASE_REVISION}"
snapshots="$(kube get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" -l "${snapshot_selector}" -o name)"
[ -n "${snapshots}" ] || fail "No Stage 1 snapshots were found for Helm revision ${RELEASE_REVISION}"

manifest_file="$(mktemp)"
trap 'rm -f "${manifest_file}"' EXIT
for component in signoz clickhouse zookeeper; do
  pvcs="$(component_pvcs "${component}")"
  [ -n "${pvcs}" ] || fail "No mounted PVC was found for ${component} after the ClickHouse upgrade"
  for pvc in ${pvcs}; do
    pvc_uid="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.metadata.uid}')"
    match=""
    for snapshot in ${snapshots}; do
      source_pvc="$(kube get "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc}')"
      source_uid="$(kube get "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc-uid}')"
      ready="$(kube get "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.status.readyToUse}')"
      if [ "${source_pvc}" = "${pvc}" ] && [ "${source_uid}" = "${pvc_uid}" ] && [ "${ready}" = "true" ]; then
        [ -z "${match}" ] || fail "Multiple ready snapshots match PVC '${pvc}' and UID '${pvc_uid}'"
        match="${snapshot#*/}"
      fi
    done
    [ -n "${match}" ] || fail "No ready snapshot matches PVC '${pvc}' and UID '${pvc_uid}'"
    printf '%s\t%s\t%s\t%s\n' "${component}" "${pvc}" "${pvc_uid}" "${match}" >>"${manifest_file}"
  done
done

completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
snapshot_manifest="$(sed 's/^/    /' "${manifest_file}")"
kube apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${MARKER_SECRET_NAME}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/instance: ${RELEASE_NAME}
    app.kubernetes.io/managed-by: Helm
    obaas.oracle.com/signoz-upgrade-marker: "true"
  annotations:
    helm.sh/resource-policy: keep
type: Opaque
stringData:
  workflow: "signoz-${TARGET_VERSION}-two-stage"
  stage: "stage1"
  status: "complete"
  releaseName: "${RELEASE_NAME}"
  namespace: "${NAMESPACE}"
  helmRevision: "${RELEASE_REVISION}"
  targetVersion: "${TARGET_VERSION}"
  clickhouseVersion: "${reported_version}"
  telemetryRows: "${telemetry_rows}"
  completedAt: "${completed_at}"
  snapshots: |-
${snapshot_manifest}
EOF

echo "ClickHouse ${reported_version} and all Stage 1 snapshots validated."
echo "Stage 1 completion marker '${MARKER_SECRET_NAME}' created."
