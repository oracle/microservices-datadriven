#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/demo-common.sh"
if ! command -v uuidgen >/dev/null 2>&1; then
  echo "This demo needs uuidgen to identify review actions." >&2
  exit 1
fi

wait_for_assistance() {
  local ticket_id="$1" previous_time="${2:-}" ticket status assistance
  for ((attempt = 0; attempt < 240; attempt++)); do
    ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")" || return
    status="$(jq -r '.workflowStatus' <<<"${ticket}")"
    if [[ "${status}" == "FAILED" || "${status}" == "TRIAGED" ]]; then
      echo "Ticket ${ticket_id} reached ${status}. Use events,ai,blockchain; inspect /ticket-events/failures before replay." >&2
      return 1
    fi
    if [[ "${status}" == "ENRICHED" ]]; then
      assistance="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}/assistance")" || return
      if jq -e --arg previous "${previous_time}" '
        (.summary | type == "string" and length > 0)
        and (.generatedAt | type == "string" and length > 0)
        and ($previous == "" or .generatedAt != $previous)
      ' <<<"${assistance}" >/dev/null; then
        printf '%s\n' "${assistance}"
        return 0
      fi
    fi
    sleep 0.5
  done
  echo "Timed out waiting for ticket ${ticket_id} assistance." >&2
  return 1
}

ticket_id="$(create_demo_ticket)"
echo "Created ticket ${ticket_id}; waiting for its first summary..."
before="$(wait_for_assistance "${ticket_id}")"
feedback="The affected account belongs to the test tenant. Include that context in the summary."
action_id="$(uuidgen)"
payload="$(jq -cn --arg actionId "${action_id}" --arg reason "${feedback}" \
  '{actionId:$actionId, decision:"REJECTED", actorId:"demo-reviewer", reason:$reason}')"
review="$(curl -fsS --max-time 30 -H 'Content-Type: application/json' -d "${payload}" \
  "${base_url}/tickets/${ticket_id}/approvals")"
jq -e --arg summary "$(jq -r '.summary' <<<"${before}")" \
  '.decision == "REJECTED" and .reviewedSummary == $summary' <<<"${review}" >/dev/null

# Reusing the same action must not append feedback or request another revision.
retry="$(curl -fsS --max-time 30 -H 'Content-Type: application/json' -d "${payload}" \
  "${base_url}/tickets/${ticket_id}/approvals")"
jq -e --arg actionId "$(jq -r '.actionId' <<<"${review}")" \
  '.actionId == $actionId' <<<"${retry}" >/dev/null

echo "Rejected the summary; waiting for regeneration through TxEventQ..."
after="$(wait_for_assistance "${ticket_id}" "$(jq -r '.generatedAt' <<<"${before}")")"
ticket="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}?readPath=primary")"
jq -e --arg feedback "${feedback}" '.reviewFeedback == $feedback' <<<"${ticket}" >/dev/null

approved_payload="$(jq -cn --arg actionId "$(uuidgen)" \
  '{actionId:$actionId, decision:"APPROVED", actorId:"demo-reviewer", reason:"Accepted the revision"}')"
approved="$(curl -fsS --max-time 30 -H 'Content-Type: application/json' -d "${approved_payload}" \
  "${base_url}/tickets/${ticket_id}/approvals")"
jq -e --arg summary "$(jq -r '.summary' <<<"${after}")" \
  '.decision == "APPROVED" and .reviewedSummary == $summary' <<<"${approved}" >/dev/null
history="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}/approvals")"
jq -e 'length == 2' <<<"${history}" >/dev/null
current="$(curl -fsS --max-time 5 "${base_url}/tickets/${ticket_id}/assistance")"
jq -e --arg generatedAt "$(jq -r '.generatedAt' <<<"${after}")" \
  '.generatedAt == $generatedAt' <<<"${current}" >/dev/null

echo "Ticket ${ticket_id}: rejected, regenerated, then approved. Two review snapshots are preserved."
jq -n --argjson before "${before}" --argjson after "${after}" \
  '{previousSummary:$before.summary, revisedSummary:$after.summary}'
