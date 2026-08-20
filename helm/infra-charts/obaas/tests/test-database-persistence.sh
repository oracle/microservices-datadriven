#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RENDERED="$(mktemp)"
trap 'rm -f "${RENDERED}"' EXIT

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_command helm
require_command grep

helm template obaas "${CHART_DIR}" \
  --namespace obaas \
  >"${RENDERED}"

grep -Fq 'name: obaas-sidb-data' "${RENDERED}"
grep -Fq 'storage: "250Gi"' "${RENDERED}"
grep -Fq 'mountPath: "/opt/oracle/oradata"' "${RENDERED}"

assert_persistence_enabled() {
  local database_type="$1"
  local database_name="$2"
  local mount_path="$3"

  helm template obaas "${CHART_DIR}" \
    --namespace obaas \
    --set "database.type=${database_type}" \
    --set database.persistence.enabled=true \
    >"${RENDERED}"

  grep -Fq "name: obaas-${database_name}-data" "${RENDERED}"
  grep -Fq 'storage: "250Gi"' "${RENDERED}"
  grep -Fq "mountPath: \"${mount_path}\"" "${RENDERED}"
}

assert_persistence_enabled SIDB-FREE sidb /opt/oracle/oradata
assert_persistence_enabled ADB-FREE adb /u01/data
