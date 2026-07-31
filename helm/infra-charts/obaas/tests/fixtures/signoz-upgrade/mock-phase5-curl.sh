#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail
SCENARIO="${MOCK_SCENARIO:-success}"
STATE_DIR="${MOCK_STATE_DIR:?}"
if [[ "$*" == *system.parts* ]]; then
  count_file="${STATE_DIR}/queries"
  count=0; [[ ! -f "${count_file}" ]] || count="$(<"${count_file}")"
  count=$((count + 1)); echo "${count}" >"${count_file}"
  if [[ "${SCENARIO}" == historical-lost ]]; then echo 99
  elif [[ "${SCENARIO}" == no-ingestion ]]; then echo 100
  elif [[ "${count}" -eq 1 ]]; then echo 100
  else echo 101
  fi
  exit 0
fi
exit 0
