#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "This demo needs jq to read the API responses." >&2
  exit 1
fi

base_url="${LAB_BASE_URL:-http://localhost:9001}"
created="$(curl -fsS --max-time 5 -H 'Content-Type: application/json' \
  -d '{"title":"[demo-fail-once] Lost MFA authenticator","description":"I lost my authenticator and cannot sign in. How can I recover access safely?"}' \
  "${base_url}/tickets")"
ticket_id="$(jq -er '.id' <<<"${created}")"
echo "Created ticket ${ticket_id} (RECEIVED); waiting for the intentional failure..."

failed_event_id=""
for ((attempt = 0; attempt < 120; attempt++)); do
  failures="$(curl -fsS --max-time 5 "${base_url}/ticket-events/failures")"
  failed_event_id="$(jq -r --argjson ticketId "${ticket_id}" \
    '[.[] | select(.ticketId == $ticketId and .failureType == "DemoFailureException" and .replayable)] | first | .eventId // empty' \
    <<<"${failures}")"
  [[ -n "${failed_event_id}" ]] && break
  ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")"
  status="$(jq -r '.workflowStatus' <<<"${ticket}")"
  if [[ "${status}" == "TRIAGED" || "${status}" == "ENRICHED" ]]; then
    echo "Ticket ${ticket_id} completed without the deliberate failure. Restart the app with events,demo-failures and rerun this script." >&2
    exit 1
  fi
  sleep 0.25
done

if [[ -z "${failed_event_id}" ]]; then
  echo "No demo failure appeared within 30 seconds. Is the app running with events,demo-failures?" >&2
  exit 1
fi

failed_ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")"
if [[ "$(jq -r '.workflowStatus' <<<"${failed_ticket}")" != "FAILED" ]]; then
  echo "Failure record appeared, but ticket ${ticket_id} is not FAILED." >&2
  exit 1
fi
echo "Event ${failed_event_id} failed and is replayable; ticket ${ticket_id} is FAILED. Replaying..."

replayed="$(curl -fsS --max-time 5 -X POST \
  "${base_url}/ticket-events/failures/${failed_event_id}/replay")"
replay_event_id="$(jq -er '.eventId' <<<"${replayed}")"
if [[ "$(jq -r '.causationId' <<<"${replayed}")" != "${failed_event_id}" ]]; then
  echo "Replay event is not linked to the original failed event." >&2
  exit 1
fi
for ((attempt = 0; attempt < 120; attempt++)); do
  ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")"
  status="$(jq -r '.workflowStatus' <<<"${ticket}")"
  if [[ "${status}" == "TRIAGED" || "${status}" == "ENRICHED" ]]; then
    repeat_status="$(curl -sS --max-time 5 -o /dev/null -w '%{http_code}' -X POST \
      "${base_url}/ticket-events/failures/${failed_event_id}/replay")"
    if [[ "${repeat_status}" != "404" ]]; then
      echo "Repeated replay returned HTTP ${repeat_status}; expected 404 and no second event." >&2
      exit 1
    fi
    echo "Replay ${replay_event_id} completed; ticket ${ticket_id} is ${status}. Repeated replay was rejected."
    LAB_TICKET_ID="${ticket_id}" "$(dirname "${BASH_SOURCE[0]}")/demo-true-cache-reads.sh"
    exit 0
  fi
  sleep 0.25
done

echo "Replay ${replay_event_id} did not complete within 30 seconds." >&2
exit 1
