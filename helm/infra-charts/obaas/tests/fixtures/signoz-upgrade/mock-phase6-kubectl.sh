#!/bin/sh
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -eu

scenario="${MOCK_SCENARIO:-legacy}"
state_dir="${MOCK_STATE_DIR:?MOCK_STATE_DIR is required}"
log_file="${MOCK_LOG:?MOCK_LOG is required}"
command_name="${1:-}"
shift || true
printf '%s %s\n' "${command_name}" "$*" >>"${log_file}"

case "${command_name}" in
  get)
    case "${1:-}" in
      statefulset)
        case "$*" in
          *jsonpath*)
            if [ "${scenario}" = "clean" ]; then
              printf '|signoz|||'
            elif [ "${scenario}" = "patch-stuck" ] || [ ! -f "${state_dir}/patched" ]; then
              printf 'accounts.google.com|signoz oidc-mock|SSL_CERT_FILE|cert-vol|mock-config cert-vol'
            else
              printf '|signoz|||'
            fi
            ;;
        esac
        exit 0
        ;;
      configmap/signoz-oidc-mock)
        [ "${scenario}" = "delete-stuck" ] && exit 0
        exit 1
        ;;
      *) exit 1 ;;
    esac
    ;;
  patch)
    : >"${state_dir}/patched"
    exit 0
    ;;
  rollout|delete) exit 0 ;;
  *)
    echo "Unexpected kubectl command: ${command_name} $*" >&2
    exit 1
    ;;
esac
