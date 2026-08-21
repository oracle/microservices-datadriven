#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

scenario="${MOCK_SCENARIO:-success}"

case "$1 $2" in
  "status obaas")
    revision=7
    status=failed
    [[ "${scenario}" == "wrong-revision" ]] && revision=8
    [[ "${scenario}" == "not-failed" ]] && status=deployed
    cat <<EOF
name: obaas
info:
  status: ${status}
version: ${revision}
EOF
    ;;
  "get values")
    stage=stage1
    [[ "${scenario}" == "wrong-stage" ]] && stage=stage2
    cat <<EOF
signozUpgrade:
  stage: ${stage}
EOF
    ;;
  "get hooks")
    cat <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: obaas-signoz-validate
spec:
  template:
    spec:
      containers:
        - name: validate
          env:
            - name: TARGET_VERSION
              value: "0.134.0"
            - name: CLICKHOUSE_VERSION
              value: "25.12.5"
            - name: MARKER_SECRET_NAME
              value: "obaas-signoz-upgrade-0-134-0-stage1"
EOF
    ;;
  *)
    echo "Unexpected helm command: $*" >&2
    exit 1
    ;;
esac
