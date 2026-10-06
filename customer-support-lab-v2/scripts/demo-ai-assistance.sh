#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/demo-common.sh"
ticket_id="$(create_demo_ticket)"
echo "Created ticket ${ticket_id}; waiting for AI enrichment and policy retrieval..."

for ((attempt = 0; attempt < 240; attempt++)); do
  ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")"
  status="$(jq -r '.workflowStatus' <<<"${ticket}")"
  if [[ "${status}" == "FAILED" ]]; then
    failures="$(curl -fsS --max-time 5 "${base_url}/ticket-events/failures")"
    failed_event_id="$(jq -r --argjson ticketId "${ticket_id}" \
      '[.[] | select(.ticketId == $ticketId and .replayable)] | first | .eventId // empty' \
      <<<"${failures}")"
    echo "Ticket ${ticket_id} failed enrichment. Inspect and fix the cause before replaying." >&2
    if [[ -n "${failed_event_id}" ]]; then
      echo "Replayable event: ${failed_event_id}" >&2
      echo "Replay command: curl -X POST '${base_url}/ticket-events/failures/${failed_event_id}/replay'" >&2
    else
      echo "Inspect ${base_url}/ticket-events/failures for the failure record." >&2
    fi
    exit 1
  fi
  if [[ "${status}" == "TRIAGED" ]]; then
    echo "Ticket ${ticket_id} was processed without AI enrichment. Restart the app with events,ai and rerun this script." >&2
    exit 1
  fi
  if [[ "${status}" == "ENRICHED" ]]; then
    assistance="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}/assistance")"
    if ! jq -e --argjson ticketId "${ticket_id}" '
      .ticketId == $ticketId
      and (.summary | type == "string" and length > 0)
      and (.summaryModel | type == "string" and length > 0)
      and (.promptVersion | type == "string" and length > 0)
      and (.policies | type == "array" and length > 0)
    ' <<<"${assistance}" >/dev/null; then
      echo "Ticket ${ticket_id} is ENRICHED but saved assistance is incomplete; check policy indexing and model configuration." >&2
      exit 1
    fi
    echo "Ticket ${ticket_id} is ENRICHED. Saved assistance:"
    jq '{summary, summaryModel, promptVersion, similarTickets, policies}' <<<"${assistance}"
    exit 0
  fi
  sleep 0.5
done

echo "Ticket ${ticket_id} did not finish enrichment within 120 seconds." >&2
exit 1
