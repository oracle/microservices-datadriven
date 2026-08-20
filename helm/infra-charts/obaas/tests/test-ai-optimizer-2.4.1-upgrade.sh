#!/usr/bin/env bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
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
  --set database.type=SIDB-FREE \
  --set database.privAuthN.secretName= \
  --set ai-optimizer.enabled=true \
  --set ai-optimizer.global.api.apiKey=test-api-key \
  --set ai-optimizer.client.cookieSecret=cccccccccccccccccccccccccccccccc \
  --set ai-optimizer.server.database.type=ADB-S \
  --set ai-optimizer.server.database.adb.useExisting=true \
  --set ai-optimizer.server.database.adb.existingWalletSource=obaas \
  --set ai-optimizer.server.database.adb.serviceName=mydb_tp \
  --set ai-optimizer.server.database.privAuthn.secretName=db-priv-authn \
  >"${RENDERED}"

grep -Fq 'secretName: obaas-adb-tns-admin-1' "${RENDERED}"
grep -Fq 'name: obaas-adb-wallet-pass-1' "${RENDERED}"
if grep -Fq 'obaas-ai-optimizer-adb-' "${RENDERED}"; then
  echo "AI Optimizer must reuse the OBaaS ADB wallet secrets" >&2
  exit 1
fi
