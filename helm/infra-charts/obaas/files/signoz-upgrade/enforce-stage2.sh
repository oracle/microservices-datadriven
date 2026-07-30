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
MARKER_SECRET_NAME="${MARKER_SECRET_NAME:?MARKER_SECRET_NAME is required}"

kube() { "${KUBECTL}" "$@"; }
fail() { echo "ERROR: Stage 2 blocked: $*" >&2; exit 1; }

marker_value() {
  key="$1"
  value="$(kube get secret "${MARKER_SECRET_NAME}" -n "${NAMESPACE}" \
    -o go-template="{{index .data \"${key}\" | base64decode}}" 2>/dev/null || true)"
  [ -n "${value}" ] || fail "completion marker '${MARKER_SECRET_NAME}' is missing required field '${key}'"
  printf '%s' "${value}"
}

kube get secret "${MARKER_SECRET_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1 || \
  fail "Stage 1 completion marker '${MARKER_SECRET_NAME}' was not found"

workflow="$(marker_value workflow)"
stage="$(marker_value stage)"
status="$(marker_value status)"
marker_release="$(marker_value releaseName)"
marker_namespace="$(marker_value namespace)"
marker_revision="$(marker_value helmRevision)"
marker_target="$(marker_value targetVersion)"
marker_clickhouse="$(marker_value clickhouseVersion)"
snapshot_manifest="$(marker_value snapshots)"

[ "${workflow}" = "signoz-${TARGET_VERSION}-two-stage" ] || fail "marker workflow '${workflow}' is invalid"
[ "${stage}" = "stage1" ] || fail "marker stage '${stage}' is invalid"
[ "${status}" = "complete" ] || fail "marker status '${status}' is not complete"
[ "${marker_release}" = "${RELEASE_NAME}" ] || fail "marker belongs to release '${marker_release}', not '${RELEASE_NAME}'"
[ "${marker_namespace}" = "${NAMESPACE}" ] || fail "marker belongs to namespace '${marker_namespace}', not '${NAMESPACE}'"
[ "${marker_target}" = "${TARGET_VERSION}" ] || fail "marker target '${marker_target}' does not match '${TARGET_VERSION}'"
case "${marker_clickhouse}" in
  "${CLICKHOUSE_VERSION}"*) ;;
  *) fail "marker ClickHouse version '${marker_clickhouse}' does not match '${CLICKHOUSE_VERSION}'" ;;
esac

expected_revision=$((RELEASE_REVISION - 1))
[ "${marker_revision}" = "${expected_revision}" ] || \
  fail "marker Helm revision '${marker_revision}' is stale; expected '${expected_revision}'"

manifest_file="$(mktemp)"
seen_components="$(mktemp)"
trap 'rm -f "${manifest_file}" "${seen_components}"' EXIT
printf '%s\n' "${snapshot_manifest}" >"${manifest_file}"

record_count=0
while IFS="$(printf '\t')" read -r component pvc recorded_uid snapshot extra; do
  [ -n "${component}" ] || continue
  [ -z "${extra:-}" ] || fail "snapshot manifest contains a malformed record"
  case "${component}" in signoz|clickhouse|zookeeper) ;; *) fail "snapshot manifest contains unknown component '${component}'" ;; esac
  [ -n "${pvc}" ] && [ -n "${recorded_uid}" ] && [ -n "${snapshot}" ] || \
    fail "snapshot manifest contains an incomplete record"

  current_uid="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.metadata.uid}' 2>/dev/null || true)"
  [ -n "${current_uid}" ] || fail "recorded PVC '${pvc}' no longer exists"
  [ "${current_uid}" = "${recorded_uid}" ] || \
    fail "PVC '${pvc}' UID changed from '${recorded_uid}' to '${current_uid}'"

  kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" >/dev/null 2>&1 || \
    fail "recorded snapshot '${snapshot}' no longer exists"
  ready="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.status.readyToUse}')"
  source_pvc="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc}')"
  source_uid="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc-uid}')"
  snapshot_revision="$(kube get volumesnapshot.snapshot.storage.k8s.io "${snapshot}" -n "${NAMESPACE}" -o jsonpath='{.metadata.labels.obaas\.oracle\.com/helm-revision}')"
  [ "${ready}" = "true" ] || fail "snapshot '${snapshot}' is not ready"
  [ "${source_pvc}" = "${pvc}" ] || fail "snapshot '${snapshot}' source PVC does not match '${pvc}'"
  [ "${source_uid}" = "${recorded_uid}" ] || fail "snapshot '${snapshot}' source PVC UID does not match '${recorded_uid}'"
  [ "${snapshot_revision}" = "${marker_revision}" ] || fail "snapshot '${snapshot}' belongs to Helm revision '${snapshot_revision}'"

  echo "${component}" >>"${seen_components}"
  record_count=$((record_count + 1))
done <"${manifest_file}"

[ "${record_count}" -gt 0 ] || fail "snapshot manifest is empty"
for required_component in signoz clickhouse zookeeper; do
  grep -qx "${required_component}" "${seen_components}" || \
    fail "snapshot manifest does not include '${required_component}'"
done

kube wait pod -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
  --for=condition=Ready --timeout="${VALIDATION_TIMEOUT}" || fail "ClickHouse pod is not Ready"
clickhouse_pod="$(kube get pods -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
  -o jsonpath='{.items[0].metadata.name}')"
clickhouse_image="$(kube get pod "${clickhouse_pod}" -n "${NAMESPACE}" -o jsonpath='{.spec.containers[?(@.name=="clickhouse")].image}')"
case "${clickhouse_image}" in *:"${CLICKHOUSE_VERSION}"|*:"${CLICKHOUSE_VERSION}"@sha256:*) ;; *) fail "live ClickHouse image '${clickhouse_image}' is not ${CLICKHOUSE_VERSION}" ;; esac

chi_name="$(kube get clickhouseinstallations.clickhouse.altinity.com -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[0].metadata.name}')"
password="$(kube get clickhouseinstallation.clickhouse.altinity.com "${chi_name}" -n "${NAMESPACE}" -o jsonpath="{.spec.configuration.users['admin/password']}")"
live_version="$(kube exec -n "${NAMESPACE}" "${clickhouse_pod}" -c clickhouse -- clickhouse-client --user admin --password "${password}" --query 'SELECT version()')"
case "${live_version}" in "${CLICKHOUSE_VERSION}"*) ;; *) fail "live ClickHouse version '${live_version}' is not ${CLICKHOUSE_VERSION}" ;; esac

echo "Stage 2 prerequisite validation passed; Helm may proceed."
