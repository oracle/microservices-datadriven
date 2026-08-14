#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE=""
RELEASE_NAME=""
STAGE=""
TIMEOUT="2m"
CLICKHOUSE_VERSION="25.12.5"
SIGNOZ_VERSION="v0.134.0"
COLLECTOR_VERSION="v0.144.6"

usage() {
  cat <<'EOF'
Usage: validate-signoz-upgrade.sh --namespace NAME --release NAME --stage STAGE [options]

Options:
  --namespace NAME          OBaaS namespace (required)
  --release NAME            OBaaS Helm release (required)
  --stage STAGE             Upgrade stage to validate: stage1 or stage2 (required)
  --timeout DURATION        Kubernetes wait timeout (default: 2m)
  --clickhouse-version TAG  Expected ClickHouse image version (default: 25.12.5)
  --signoz-version TAG      Expected Stage 2 SigNoZ version (default: v0.134.0)
  --collector-version TAG   Expected Stage 2 collector version (default: v0.144.6)
  -h, --help                Show this help

Environment overrides:
  KUBECTL
EOF
}

fail() {
  echo "Validation FAILED: $*" >&2
  exit 1
}

kube() {
  "${KUBECTL}" "$@"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --namespace|--release|--stage|--timeout|--clickhouse-version|--signoz-version|--collector-version)
      option="$1"
      [[ "$#" -ge 2 ]] || fail "${option} requires a value"
      case "${option}" in
        --namespace) NAMESPACE="$2" ;;
        --release) RELEASE_NAME="$2" ;;
        --stage) STAGE="$2" ;;
        --timeout) TIMEOUT="$2" ;;
        --clickhouse-version) CLICKHOUSE_VERSION="$2" ;;
        --signoz-version) SIGNOZ_VERSION="$2" ;;
        --collector-version) COLLECTOR_VERSION="$2" ;;
      esac
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
[[ -n "${STAGE}" ]] || fail "--stage is required"
case "${STAGE}" in stage1|stage2) ;; *) fail "--stage must be stage1 or stage2" ;; esac

marker_name="$(kube get secret -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-marker=true" \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
[[ -n "${marker_name}" ]] || fail "Stage 1 completion marker was not found"

marker_value() {
  local key="$1"
  local value
  value="$(kube get secret "${marker_name}" -n "${NAMESPACE}" \
    -o go-template="{{index .data \"${key}\" | base64decode}}" 2>/dev/null || true)"
  [[ -n "${value}" ]] || fail "completion marker is missing '${key}'"
  printf '%s' "${value}"
}

marker_stage="$(marker_value stage)"
marker_status="$(marker_value status)"
marker_release="$(marker_value releaseName)"
marker_namespace="$(marker_value namespace)"
marker_clickhouse="$(marker_value clickhouseVersion)"
snapshot_manifest="$(marker_value snapshots)"

[[ "${marker_stage}" == "stage1" ]] || fail "completion marker stage is '${marker_stage}'"
[[ "${marker_status}" == "complete" ]] || fail "completion marker status is '${marker_status}'"
[[ "${marker_release}" == "${RELEASE_NAME}" ]] || fail "completion marker belongs to release '${marker_release}'"
[[ "${marker_namespace}" == "${NAMESPACE}" ]] || fail "completion marker belongs to namespace '${marker_namespace}'"
[[ "${marker_clickhouse}" == "${CLICKHOUSE_VERSION}"* ]] || \
  fail "completion marker reports ClickHouse ${marker_clickhouse}, expected ${CLICKHOUSE_VERSION}"

manifest_file="$(mktemp)"
components_file="$(mktemp)"
trap 'rm -f "${manifest_file}" "${components_file}"' EXIT
printf '%s\n' "${snapshot_manifest}" >"${manifest_file}"

snapshot_count=0
while IFS=$'\t' read -r component pvc recorded_uid snapshot extra; do
  [[ -n "${component}" ]] || continue
  [[ -z "${extra:-}" && -n "${pvc}" && -n "${recorded_uid}" && -n "${snapshot}" ]] || \
    fail "completion marker contains a malformed snapshot record"
  case "${component}" in signoz|clickhouse|zookeeper) ;; *) fail "unknown snapshot component '${component}'" ;; esac

  current_uid="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.metadata.uid}' 2>/dev/null || true)"
  [[ "${current_uid}" == "${recorded_uid}" ]] || fail "PVC '${pvc}' identity changed after Stage 1"
  ready="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" \
    -o jsonpath='{.status.readyToUse}' 2>/dev/null || true)"
  [[ "${ready}" == "true" ]] || fail "snapshot '${snapshot}' is not ready"

  printf '%s\n' "${component}" >>"${components_file}"
  snapshot_count=$((snapshot_count + 1))
done <"${manifest_file}"

[[ "${snapshot_count}" -gt 0 ]] || fail "completion marker snapshot manifest is empty"
for component in signoz clickhouse zookeeper; do
  grep -qx "${component}" "${components_file}" || fail "no ready ${component} snapshot was recorded"
done

kube wait pod -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
  --for=condition=Ready --timeout="${TIMEOUT}" >/dev/null || fail "ClickHouse is not Ready"
clickhouse_image="$(kube get pods -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
  -o jsonpath='{.items[0].spec.containers[?(@.name=="clickhouse")].image}')"
case "${clickhouse_image}" in
  *:"${CLICKHOUSE_VERSION}"|*:"${CLICKHOUSE_VERSION}"@sha256:*) ;;
  *) fail "ClickHouse image '${clickhouse_image}' is not ${CLICKHOUSE_VERSION}" ;;
esac

if [[ "${STAGE}" == "stage1" ]]; then
  echo "Stage 1 validation PASSED"
  echo "Snapshots: ${snapshot_count}/${snapshot_count} ready"
  echo "ClickHouse: ready, version ${CLICKHOUSE_VERSION}"
  echo "Completion marker: valid"
  echo "Stage 2 may now be run"
  exit 0
fi

kube wait job/signoz-telemetrystore-migrator -n "${NAMESPACE}" \
  --for=condition=Complete --timeout="${TIMEOUT}" >/dev/null || fail "telemetry migrations did not complete"
kube wait "job/${RELEASE_NAME}-signoz-setup" -n "${NAMESPACE}" \
  --for=condition=Complete --timeout="${TIMEOUT}" >/dev/null || fail "SigNoZ setup did not complete"
kube wait pod -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=signoz" \
  --for=condition=Ready --timeout="${TIMEOUT}" >/dev/null || fail "SigNoZ is not Ready"
kube wait pod -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=otel-collector" \
  --for=condition=Ready --timeout="${TIMEOUT}" >/dev/null || fail "collector is not Ready"

signoz_image="$(kube get pods -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=signoz" \
  -o jsonpath='{.items[0].spec.containers[?(@.name=="signoz")].image}')"
collector_image="$(kube get pods -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=otel-collector" \
  -o jsonpath='{.items[0].spec.containers[?(@.name=="collector")].image}')"
case "${signoz_image}" in *:"${SIGNOZ_VERSION}"|*:"${SIGNOZ_VERSION}"@sha256:*) ;; *) fail "SigNoZ image '${signoz_image}' is not ${SIGNOZ_VERSION}" ;; esac
case "${collector_image}" in *:"${COLLECTOR_VERSION}"|*:"${COLLECTOR_VERSION}"@sha256:*) ;; *) fail "collector image '${collector_image}' is not ${COLLECTOR_VERSION}" ;; esac

echo "Stage 2 validation PASSED"
echo "SigNoZ: ready, version ${SIGNOZ_VERSION}"
echo "Collector: ready, version ${COLLECTOR_VERSION}"
echo "ClickHouse: ready, version ${CLICKHOUSE_VERSION}"
echo "Migrations and setup: complete"
echo "Existing users, dashboards, and telemetry must still be verified in the SigNoZ UI"
