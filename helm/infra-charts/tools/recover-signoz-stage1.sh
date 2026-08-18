#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

KUBECTL="${KUBECTL:-kubectl}"
HELM="${HELM:-helm}"
NAMESPACE=""
RELEASE_NAME=""
FAILED_REVISION=""

usage() {
  cat <<'EOF'
Usage: recover-signoz-stage1.sh --namespace NAME --release NAME --revision NUMBER

Completes validation for a failed SigNoZ Stage 1 Helm revision when its
snapshots and ClickHouse upgrade succeeded but its completion marker is absent.

Options:
  --namespace NAME   OBaaS namespace (required)
  --release NAME     OBaaS Helm release (required)
  --revision NUMBER  Failed Stage 1 Helm revision (required)
  -h, --help         Show this help

Environment overrides:
  KUBECTL, HELM
EOF
}

diagnostics_command() {
  cat >&2 <<EOF
No completion marker was created.
Collect read-only diagnostics with:
  collect-signoz-upgrade-diagnostics.sh --namespace ${NAMESPACE} --release ${RELEASE_NAME} >signoz-upgrade-diagnostics.txt 2>&1
Review the file before sharing it because it can contain workload logs.
EOF
}

fail() {
  echo "Stage 1 recovery FAILED: $*" >&2
  if [[ -n "${NAMESPACE}" && -n "${RELEASE_NAME}" ]]; then
    diagnostics_command
  fi
  exit 1
}

kube() {
  "${KUBECTL}" "$@"
}

helm_cmd() {
  "${HELM}" "$@"
}

yaml_value() {
  local key="$1"
  awk -v key="${key}" '
    $1 == key ":" {
      $1 = ""
      sub(/^[[:space:]]+/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  '
}

stage_value() {
  awk '
    /^signozUpgrade:[[:space:]]*$/ { in_upgrade = 1; next }
    in_upgrade && /^[^[:space:]]/ { exit }
    in_upgrade && $1 == "stage:" {
      value = $2
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  '
}

hook_env_value() {
  local key="$1"
  awk -v key="${key}" '
    $1 == "-" && $2 == "name:" && $3 == key {
      if (getline > 0 && $1 == "value:") {
        $1 = ""
        sub(/^[[:space:]]+/, "")
        gsub(/^"|"$/, "")
        print
        exit
      }
    }
  '
}

component_pvcs() {
  local component="$1"
  kube get pods -n "${NAMESPACE}" \
    -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=${component}" \
    -o jsonpath='{range .items[*]}{range .spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}{end}' \
    | sed '/^$/d' | sort -u
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --namespace|--release|--revision)
      option="$1"
      [[ "$#" -ge 2 ]] || fail "${option} requires a value"
      case "${option}" in
        --namespace) NAMESPACE="$2" ;;
        --release) RELEASE_NAME="$2" ;;
        --revision) FAILED_REVISION="$2" ;;
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
[[ -n "${FAILED_REVISION}" ]] || fail "--revision is required"
[[ "${FAILED_REVISION}" =~ ^[1-9][0-9]*$ ]] || fail "--revision must be a positive integer"

echo "=== Recovering SigNoZ Stage 1 validation ==="
echo "Release: ${RELEASE_NAME}/${NAMESPACE}"
echo "Failed revision: ${FAILED_REVISION}"

release_status_yaml="$(helm_cmd status "${RELEASE_NAME}" -n "${NAMESPACE}" -o yaml)" || \
  fail "unable to read Helm release status"
current_revision="$(printf '%s\n' "${release_status_yaml}" | yaml_value version)"
current_status="$(printf '%s\n' "${release_status_yaml}" | yaml_value status)"
[[ "${current_revision}" == "${FAILED_REVISION}" ]] || \
  fail "revision ${FAILED_REVISION} is not the latest Helm revision (${current_revision:-unknown})"
[[ "${current_status}" == "failed" ]] || \
  fail "Helm revision ${FAILED_REVISION} has status '${current_status:-unknown}', not 'failed'"

failed_values="$(helm_cmd get values "${RELEASE_NAME}" -n "${NAMESPACE}" \
  --revision "${FAILED_REVISION}" -o yaml)" || fail "unable to read values for revision ${FAILED_REVISION}"
failed_stage="$(printf '%s\n' "${failed_values}" | stage_value)"
[[ "${failed_stage}" == "stage1" ]] || \
  fail "Helm revision ${FAILED_REVISION} used signozUpgrade.stage='${failed_stage:-unknown}', not 'stage1'"

failed_hooks="$(helm_cmd get hooks "${RELEASE_NAME}" -n "${NAMESPACE}" \
  --revision "${FAILED_REVISION}")" || fail "unable to read hooks for revision ${FAILED_REVISION}"
target_version="$(printf '%s\n' "${failed_hooks}" | hook_env_value TARGET_VERSION)"
clickhouse_version="$(printf '%s\n' "${failed_hooks}" | hook_env_value CLICKHOUSE_VERSION)"
marker_name="$(printf '%s\n' "${failed_hooks}" | hook_env_value MARKER_SECRET_NAME)"
[[ -n "${target_version}" ]] || fail "failed revision does not contain the Stage 1 target version"
[[ -n "${clickhouse_version}" ]] || fail "failed revision does not contain the Stage 1 ClickHouse version"
[[ -n "${marker_name}" ]] || fail "failed revision does not contain the Stage 1 marker name"

if kube get secret "${marker_name}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  fail "completion marker '${marker_name}' already exists; use validate-signoz-upgrade.sh instead"
fi

snapshot_selector="app.kubernetes.io/instance=${RELEASE_NAME},obaas.oracle.com/signoz-upgrade-snapshot=true,obaas.oracle.com/helm-revision=${FAILED_REVISION}"
snapshots="$(kube get volumesnapshot.snapshot.storage.k8s.io -n "${NAMESPACE}" \
  -l "${snapshot_selector}" -o name)" || fail "unable to read Stage 1 snapshots"
[[ -n "${snapshots}" ]] || fail "no snapshots exist for failed Helm revision ${FAILED_REVISION}"

manifest_file="$(mktemp)"
trap 'rm -f "${manifest_file}"' EXIT
for component in signoz clickhouse zookeeper; do
  pvcs="$(component_pvcs "${component}")" || fail "unable to find ${component} PVCs"
  [[ -n "${pvcs}" ]] || fail "no mounted PVC was found for ${component}"
  for pvc in ${pvcs}; do
    pvc_uid="$(kube get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.metadata.uid}')" || \
      fail "unable to read PVC '${pvc}'"
    match=""
    for snapshot in ${snapshots}; do
      source_pvc="$(kube get "${snapshot}" -n "${NAMESPACE}" \
        -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc}')" || \
        fail "unable to read snapshot '${snapshot#*/}'"
      source_uid="$(kube get "${snapshot}" -n "${NAMESPACE}" \
        -o jsonpath='{.metadata.annotations.obaas\.oracle\.com/source-pvc-uid}')" || \
        fail "unable to read snapshot '${snapshot#*/}'"
      ready="$(kube get "${snapshot}" -n "${NAMESPACE}" \
        -o jsonpath='{.status.readyToUse}')" || fail "unable to read snapshot '${snapshot#*/}'"
      if [[ "${source_pvc}" == "${pvc}" && "${source_uid}" == "${pvc_uid}" && "${ready}" == "true" ]]; then
        [[ -z "${match}" ]] || fail "multiple ready snapshots match PVC '${pvc}' and UID '${pvc_uid}'"
        match="${snapshot#*/}"
      fi
    done
    [[ -n "${match}" ]] || fail "no ready snapshot matches PVC '${pvc}' and UID '${pvc_uid}'"
    printf '%s\t%s\t%s\t%s\n' "${component}" "${pvc}" "${pvc_uid}" "${match}" >>"${manifest_file}"
  done
done

clickhouse_pod="$(kube get pods -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/name=clickhouse,app.kubernetes.io/component=clickhouse" \
  -o jsonpath='{.items[0].metadata.name}')" || fail "unable to find the ClickHouse pod"
[[ -n "${clickhouse_pod}" ]] || fail "no ClickHouse pod was found"
kube wait pod "${clickhouse_pod}" -n "${NAMESPACE}" --for=condition=Ready --timeout=2m >/dev/null || \
  fail "ClickHouse pod '${clickhouse_pod}' is not Ready"
clickhouse_image="$(kube get pod "${clickhouse_pod}" -n "${NAMESPACE}" \
  -o jsonpath='{.spec.containers[?(@.name=="clickhouse")].image}')" || fail "unable to read the ClickHouse image"
case "${clickhouse_image}" in
  *:"${clickhouse_version}"|*:"${clickhouse_version}"@sha256:*) ;;
  *) fail "ClickHouse image '${clickhouse_image}' is not ${clickhouse_version}" ;;
esac

chi_name="$(kube get clickhouseinstallations.clickhouse.altinity.com -n "${NAMESPACE}" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[0].metadata.name}')" || \
  fail "unable to find the ClickHouseInstallation"
[[ -n "${chi_name}" ]] || fail "no ClickHouseInstallation was found"
clickhouse_password="$(kube get clickhouseinstallation.clickhouse.altinity.com "${chi_name}" -n "${NAMESPACE}" \
  -o jsonpath="{.spec.configuration.users['admin/password']}")" || fail "unable to read ClickHouse credentials"
reported_version="$(kube exec -n "${NAMESPACE}" "${clickhouse_pod}" -c clickhouse -- \
  clickhouse-client --user admin --password "${clickhouse_password}" --query 'SELECT version()')" || \
  fail "unable to query ClickHouse"
[[ "${reported_version}" == "${clickhouse_version}"* ]] || \
  fail "ClickHouse reports ${reported_version}, expected ${clickhouse_version}"
telemetry_rows="$(kube exec -n "${NAMESPACE}" "${clickhouse_pod}" -c clickhouse -- \
  clickhouse-client --user admin --password "${clickhouse_password}" \
  --query "SELECT toString(sum(rows)) FROM system.parts WHERE active AND startsWith(database, 'signoz_')")" || \
  fail "unable to query historical telemetry rows"
[[ "${telemetry_rows}" =~ ^[0-9]+$ ]] || fail "ClickHouse returned an invalid telemetry row count"

completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
snapshot_manifest="$(sed 's/^/    /' "${manifest_file}")"
if ! kube create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${marker_name}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/instance: ${RELEASE_NAME}
    app.kubernetes.io/managed-by: Helm
    obaas.oracle.com/signoz-upgrade-marker: "true"
  annotations:
    helm.sh/resource-policy: keep
type: Opaque
stringData:
  workflow: "signoz-${target_version}-two-stage"
  stage: "stage1"
  status: "complete"
  releaseName: "${RELEASE_NAME}"
  namespace: "${NAMESPACE}"
  helmRevision: "${FAILED_REVISION}"
  targetVersion: "${target_version}"
  clickhouseVersion: "${reported_version}"
  telemetryRows: "${telemetry_rows}"
  completedAt: "${completed_at}"
  snapshots: |-
${snapshot_manifest}
EOF
then
  fail "unable to create completion marker '${marker_name}'"
fi

snapshot_count="$(wc -l <"${manifest_file}" | tr -d ' ')"
echo "Stage 1 recovery validation PASSED"
echo "Snapshots: ${snapshot_count}/${snapshot_count} ready and matched to live PVCs"
echo "ClickHouse: ready, version ${reported_version}"
echo "Completion marker: '${marker_name}' created for revision ${FAILED_REVISION}"
echo "Next required step: run validate-signoz-upgrade.sh --stage stage1"
