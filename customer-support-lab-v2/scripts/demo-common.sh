#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Shared setup for the three HTTP demos; sourced by their entry points.
if ! command -v jq >/dev/null 2>&1; then
  echo "This demo needs jq to read the API responses." >&2
  exit 1
fi

base_url="${LAB_BASE_URL:-http://localhost:9001}"

create_demo_ticket() {
  local payload created
  payload="$(jq -cn --arg title "${1:-Lost MFA authenticator}" \
    '{title: $title, description: "I lost my authenticator and cannot sign in. How can I recover access safely?"}')"
  created="$(curl -fsS --max-time 5 -H 'Content-Type: application/json' \
    -d "${payload}" "${base_url}/tickets")" || return
  jq -er '.id' <<<"${created}"
}
