#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${CHART_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
TOOLS_DIR="${CHART_DIR}/../tools"
PREPARE="${TOOLS_DIR}/prepare-oke-volume-snapshots.sh"
VALIDATE="${TOOLS_DIR}/validate-signoz-upgrade.sh"
COLLECT="${TOOLS_DIR}/collect-signoz-upgrade-diagnostics.sh"
RESTORE="${TOOLS_DIR}/validate-signoz-snapshot-restore.sh"
MOCK="${SCRIPT_DIR}/fixtures/signoz-upgrade/mock-oke-preflight-kubectl.sh"
CLI_MOCK="${SCRIPT_DIR}/fixtures/signoz-upgrade/mock-upgrade-cli-kubectl.sh"
OKE_VALUES="${CHART_DIR}/examples/values-signoz-0.134-stage1-oke.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

assert_contains() {
  grep -Fq -- "$2" "$1" || {
    echo "Expected $1 to contain: $2" >&2
    exit 1
  }
}

assert_not_contains() {
  if grep -Fq -- "$2" "$1"; then
    echo "Expected $1 not to contain: $2" >&2
    exit 1
  fi
}

chmod +x "${MOCK}"
chmod +x "${CLI_MOCK}"
bash -n "${PREPARE}"
bash -n "${VALIDATE}"
bash -n "${COLLECT}"
bash -n "${RESTORE}"

for tool in "${PREPARE}" "${COLLECT}" "${RESTORE}"; do
  tool_name="$(basename "${tool}")"
  "${tool}" --help >"${TMP}/${tool_name}.help"
  assert_contains "${TMP}/${tool_name}.help" '--namespace NAME'
  assert_contains "${TMP}/${tool_name}.help" '--release NAME'

  if "${tool}" >"${TMP}/${tool_name}.missing.log" 2>&1; then
    echo "Expected ${tool_name} to require explicit release scope" >&2
    exit 1
  fi
  assert_contains "${TMP}/${tool_name}.missing.log" '--namespace is required'

  if "${tool}" --namespace obaas >"${TMP}/${tool_name}.missing-release.log" 2>&1; then
    echo "Expected ${tool_name} to require an explicit Helm release" >&2
    exit 1
  fi
  assert_contains "${TMP}/${tool_name}.missing-release.log" '--release is required'
done

if "${COLLECT}" obaas obaas >"${TMP}/collect-positional.log" 2>&1; then
  echo "Expected collect-signoz-upgrade-diagnostics.sh to reject positional scope arguments" >&2
  exit 1
fi
assert_contains "${TMP}/collect-positional.log" 'unknown option: obaas'

"${VALIDATE}" --help >"${TMP}/validate.help"
assert_contains "${TMP}/validate.help" '--namespace NAME'
assert_contains "${TMP}/validate.help" '--release NAME'
assert_contains "${TMP}/validate.help" '--stage STAGE'
if "${VALIDATE}" --namespace obaas --release obaas >"${TMP}/validate-missing-stage.log" 2>&1; then
  echo "Expected validate-signoz-upgrade.sh to require an explicit stage" >&2
  exit 1
fi
assert_contains "${TMP}/validate-missing-stage.log" '--stage is required'

env KUBECTL="${MOCK}" MOCK_STATE_DIR="${TMP}" \
  "${PREPARE}" --namespace obaas --release obaas >"${TMP}/prepare.log"

assert_not_contains "${TMP}/kubectl.log" 'apply -f'
assert_not_contains "${TMP}/kubectl.log" 'create -f'
assert_contains "${TMP}/prepare.log" "Existing VolumeSnapshotClass 'obaas-oci-bv-snapshot' is compatible."
assert_contains "${TMP}/prepare.log" 'Validated signoz'
assert_contains "${TMP}/prepare.log" 'OKE snapshot prerequisites are ready.'

if env KUBECTL="${MOCK}" MOCK_STATE_DIR="${TMP}" MOCK_SCENARIO=missing-crd \
  "${PREPARE}" --namespace obaas --release obaas >"${TMP}/missing-crd.log" 2>&1; then
  echo "Expected OKE preparation to reject a missing snapshot CRD" >&2
  exit 1
fi
assert_contains "${TMP}/missing-crd.log" 'Ask the cluster administrator to configure OKE VolumeSnapshot support'

if env KUBECTL="${MOCK}" MOCK_STATE_DIR="${TMP}" MOCK_SCENARIO=missing-class \
  "${PREPARE}" --namespace obaas --release obaas >"${TMP}/missing-class.log" 2>&1; then
  echo "Expected OKE preparation to reject a missing VolumeSnapshotClass" >&2
  exit 1
fi
assert_contains "${TMP}/missing-class.log" 'Ask the cluster administrator to create a retained, full-backup class'

if env KUBECTL="${MOCK}" MOCK_STATE_DIR="${TMP}" MOCK_SCENARIO=wrong-driver \
  "${PREPARE}" --namespace obaas --release obaas >"${TMP}/wrong-driver.log" 2>&1; then
  echo "Expected OKE preparation to reject a mismatched PV driver" >&2
  exit 1
fi
assert_contains "${TMP}/wrong-driver.log" "does not match StorageClass provisioner"

assert_contains "${OKE_VALUES}" 'volumeSnapshotClassName: obaas-oci-bv-snapshot'
env KUBECTL="${CLI_MOCK}" "${VALIDATE}" --namespace obaas --release obaas --stage stage1 \
  >"${TMP}/validate-stage1.log"
assert_contains "${TMP}/validate-stage1.log" 'Stage 1 validation PASSED'
assert_contains "${TMP}/validate-stage1.log" 'Snapshots: 3/3 ready'
assert_contains "${TMP}/validate-stage1.log" 'Stage 2 may now be run'

env KUBECTL="${CLI_MOCK}" "${VALIDATE}" --namespace obaas --release obaas --stage stage2 \
  >"${TMP}/validate-stage2.log"
assert_contains "${TMP}/validate-stage2.log" 'Stage 2 validation PASSED'
assert_contains "${TMP}/validate-stage2.log" 'Migrations and setup: complete'

if env KUBECTL="${CLI_MOCK}" MOCK_SCENARIO=snapshot-not-ready \
  "${VALIDATE}" --namespace obaas --release obaas --stage stage1 \
  >"${TMP}/validate-failed.log" 2>&1; then
  echo "Expected upgrade validation to reject an unready snapshot" >&2
  exit 1
fi
assert_contains "${TMP}/validate-failed.log" "Validation FAILED: snapshot 'snap-clickhouse' is not ready"

if env KUBECTL="${CLI_MOCK}" MOCK_SCENARIO=missing-marker \
  "${VALIDATE}" --namespace obaas --release obaas --stage stage1 \
  >"${TMP}/validate-missing-marker.log" 2>&1; then
  echo "Expected upgrade validation to reject a missing completion marker" >&2
  exit 1
fi
assert_contains "${TMP}/validate-missing-marker.log" 'Validation FAILED: Stage 1 completion marker was not found'

if env KUBECTL="${CLI_MOCK}" MOCK_SCENARIO=stage2-not-ready \
  "${VALIDATE}" --namespace obaas --release obaas --stage stage2 \
  >"${TMP}/validate-stage2-failed.log" 2>&1; then
  echo "Expected Stage 2 validation to reject an incomplete migration Job" >&2
  exit 1
fi
assert_contains "${TMP}/validate-stage2-failed.log" 'Validation FAILED: telemetry migrations did not complete'

assert_contains "${COLLECT}" 'Stage 1 completion marker'
assert_contains "${COLLECT}" 'obaas.oracle.com/signoz-upgrade-marker=true'
assert_contains "${COLLECT}" '--include-identifiers'
assert_contains "${RESTORE}" 'Snapshot restore validation passed.'
assert_contains "${RESTORE}" 'dataSource:'
assert_contains "${RESTORE}" 'kind: VolumeSnapshot'
assert_contains "${RESTORE}" ".status.restoreSize"
assert_contains "${RESTORE}" 'shasum -a 256'

echo "SigNoZ OKE snapshot tooling regression test passed"
