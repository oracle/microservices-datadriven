#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${CHART_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
RECOVER="${CHART_DIR}/../tools/recover-signoz-stage1.sh"
TOOLS_README="${CHART_DIR}/../tools/README.md"
RECOVERY_DOC="${CHART_DIR}/../../../docs-source/site/docs/observability/upgrade/protected-recovery.md"
MOCK_HELM="${SCRIPT_DIR}/fixtures/signoz-upgrade/mock-stage1-recovery-helm.sh"
MOCK_KUBECTL="${SCRIPT_DIR}/fixtures/signoz-upgrade/mock-stage1-recovery-kubectl.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

assert_contains() {
  grep -Fq -- "$2" "$1" || { echo "Expected $1 to contain: $2" >&2; exit 1; }
}

chmod +x "${MOCK_HELM}" "${MOCK_KUBECTL}"
bash -n "${RECOVER}" "${MOCK_HELM}" "${MOCK_KUBECTL}"

run_recovery() {
  local scenario="$1"
  local case_dir="${TMP}/${scenario}"
  mkdir -p "${case_dir}"
  env HELM="${MOCK_HELM}" KUBECTL="${MOCK_KUBECTL}" \
    MOCK_SCENARIO="${scenario}" MOCK_OUTPUT_DIR="${case_dir}" \
    bash "${RECOVER}" --namespace obaas --release obaas --revision 7 \
    >"${case_dir}/output.log" 2>&1
}

run_recovery success
assert_contains "${TMP}/success/output.log" 'Stage 1 recovery validation PASSED'
assert_contains "${TMP}/success/output.log" 'Snapshots: 3/3 ready and matched to live PVCs'
assert_contains "${TMP}/success/output.log" 'Next required step: run validate-signoz-upgrade.sh --stage stage1'
assert_contains "${TMP}/success/marker.yaml" 'name: obaas-signoz-upgrade-0-134-0-stage1'
assert_contains "${TMP}/success/marker.yaml" 'helmRevision: "7"'
assert_contains "${TMP}/success/marker.yaml" $'clickhouse\tclickhouse-pvc\tuid-clickhouse-pvc\tsnap-clickhouse'

for scenario in wrong-revision not-failed wrong-stage marker-exists snapshot-not-ready wrong-clickhouse create-fails; do
  if run_recovery "${scenario}"; then
    echo "Expected recovery scenario '${scenario}' to fail" >&2
    exit 1
  fi
  assert_contains "${TMP}/${scenario}/output.log" 'Stage 1 recovery FAILED:'
  assert_contains "${TMP}/${scenario}/output.log" 'collect-signoz-upgrade-diagnostics.sh --namespace obaas --release obaas'
  [[ ! -e "${TMP}/${scenario}/marker.yaml" ]] || {
    echo "Recovery scenario '${scenario}' unexpectedly created a marker" >&2
    exit 1
  }
done

assert_contains "${TMP}/wrong-revision/output.log" 'is not the latest Helm revision'
assert_contains "${TMP}/not-failed/output.log" "status 'deployed', not 'failed'"
assert_contains "${TMP}/wrong-stage/output.log" "signozUpgrade.stage='stage2', not 'stage1'"
assert_contains "${TMP}/marker-exists/output.log" 'already exists; use validate-signoz-upgrade.sh instead'
assert_contains "${TMP}/snapshot-not-ready/output.log" "no ready snapshot matches PVC 'clickhouse-pvc'"
assert_contains "${TMP}/wrong-clickhouse/output.log" "is not 25.12.5"
assert_contains "${TMP}/create-fails/output.log" 'unable to create completion marker'

assert_contains "${RECOVERY_DOC}" 'recover-signoz-stage1.sh'
assert_contains "${RECOVERY_DOC}" 'Review the diagnostics file before sharing it'
assert_contains "${RECOVERY_DOC}" 'Proceed to Stage 2 only after both commands pass.'
assert_contains "${TOOLS_README}" '### recover-signoz-stage1.sh'

echo "SigNoZ Stage 1 recovery tooling regression test passed"
