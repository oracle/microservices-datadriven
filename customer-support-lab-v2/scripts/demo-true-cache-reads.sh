#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "This demo needs jq to read the API responses." >&2
  exit 1
fi

base_url="${LAB_BASE_URL:-http://localhost:9001}"
ticket_id="${LAB_TICKET_ID:-}"
if [[ -z "${ticket_id}" ]]; then
  created="$(curl -fsS --max-time 5 -H 'Content-Type: application/json' \
    -d '{"title":"Lost MFA authenticator","description":"I lost my authenticator and cannot sign in. How can I recover access safely?"}' \
    "${base_url}/tickets")"
  ticket_id="$(jq -er '.id' <<<"${created}")"
  echo "Created ticket ${ticket_id} for the read-path check."
elif [[ ! "${ticket_id}" =~ ^[1-9][0-9]*$ ]]; then
  echo "LAB_TICKET_ID must be a positive numeric ticket ID." >&2
  exit 1
fi
echo "Checking ticket ${ticket_id} on primary and True Cache..."

for path in primary cache; do
  expected_read_path="primary"
  [[ "${path}" == "cache" ]] && expected_read_path="true-cache"
  for ((attempt = 0; attempt < 30; attempt++)); do
    response="$(curl -sS -i --max-time 5 -w '\n__HTTP_STATUS__:%{http_code}' \
      "${base_url}/tickets/${ticket_id}?readPath=${path}")"
    status="${response##*__HTTP_STATUS__:}"
    headers_and_body="${response%$'\n'__HTTP_STATUS__:*}"
    read_path="$(awk 'tolower($1) == "x-read-path:" {gsub("\r", "", $2); print $2; exit}' <<<"${headers_and_body}")"

    if [[ "${path}" == "cache" && "${read_path}" == "true-cache" && "${status}" == "404" ]]; then
      sleep 1
      continue
    fi
    if [[ "${status}" != "200" || "${read_path}" != "${expected_read_path}" ]]; then
      echo "${path}: HTTP ${status}, X-Read-Path: ${read_path:-missing}"
      echo "The ${path} read did not succeed on its requested path; check True Cache setup and the app connection." >&2
      exit 1
    fi
    body="${headers_and_body#*$'\r\n\r\n'}"
    if [[ "${body}" == "${headers_and_body}" ]]; then
      echo "The ${path} response had no JSON body." >&2
      exit 1
    fi
    observed_id="$(jq -er '.id' <<<"${body}")"
    workflow_status="$(jq -er '.workflowStatus' <<<"${body}")"
    if [[ "${observed_id}" != "${ticket_id}" ]]; then
      echo "The ${path} response returned ticket ${observed_id}, expected ${ticket_id}." >&2
      exit 1
    fi
    echo "${path}: HTTP ${status}, X-Read-Path: ${read_path}, workflow status: ${workflow_status}"
    break
  done
  if [[ "${path}" == "cache" && "${status}" == "404" ]]; then
    echo "Ticket ${ticket_id} was not visible on True Cache after 30 seconds; check redo apply." >&2
    exit 1
  fi
done

echo "Primary and True Cache both served ticket ${ticket_id}; a cache miss was never replaced with a primary read."
