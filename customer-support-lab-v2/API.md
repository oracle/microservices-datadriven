# Customer Support Lab API reference

Use the [UI walkthrough](README.md#1-explore-the-workspace) to run the lab.
This reference describes the endpoints used by the console. The Java application
serves them at `http://localhost:9001`; JSON request bodies use
`Content-Type: application/json`. These local lab APIs have no authentication.
Reviewer identities are self-declared.

## Endpoints

| Method | Path | Behavior |
| --- | --- | --- |
| GET | `/api/lab` | Current table counts, configured models, topic, policies and indexing state, and review states. Counts do not establish service health. |
| POST | `/tickets` | Commit a ticket and work event together; return the ticket with its assigned ID. Processing continues asynchronously and may call OCI. |
| GET | `/tickets?readPath=primary` | List tickets from the requested read path. |
| GET | `/tickets/{id}?readPath=primary` | Read one ticket; 404 when absent. |
| GET | `/tickets/{id}/assistance` | Saved summary, suggested resolution, model, prompt version, generation timestamp, policies, and similar tickets. Returns 404 while assistance is unavailable. |
| POST | `/tickets/{id}/approvals` | Record approval or request a revision of saved assistance. |
| GET | `/tickets/{id}/approvals` | Review history with saved assistance snapshots and digests; 404 for an unknown ticket. |
| GET | `/ticket-events/failures` | Current replayable failures with event IDs, ticket IDs, errors, and attempt metadata. |
| POST | `/ticket-events/failures/{eventId}/replay` | Publish a replacement event; return 202 with the envelope. Returns 404 when the replayable failure no longer exists or 409 for a workflow conflict. |

## Ticket submission

```json
{
  "title": "Lost MFA authenticator",
  "description": "I replaced my phone and cannot sign in. How can I restore access without bypassing MFA?"
}
```

An optional `X-Correlation-ID` header accepts a UUID. Omit it to generate one.
Submit title and description only; `suggestedResolution` belongs to generated
assistance. New tickets begin at `RECEIVED` and should reach `ENRICHED`.
`FAILED` indicates a processing failure; `TRIAGED` identifies imported reference
cases. Assistance can describe an earlier generation while a revision is being
processed. Check workflow status and `generatedAt` before reviewing a revision.

## Reviews

```json
{
  "actionId": "b2266020-cef6-483d-9ead-41f69b53d458",
  "decision": "REJECTED",
  "actorId": "demo-reviewer",
  "reason": "The affected account belongs to the test tenant. Include that context in the summary."
}
```

Use a new `actionId` UUID for each decision. Retry an uncertain response with
the same action ID and payload. `decision` is `APPROVED` or `REJECTED`;
`actorId` must contain 1–128 characters. `reason` is optional for approval,
required and nonblank for rejection, and limited to 1000 characters.

Rejection saves a review snapshot, appends feedback, and publishes regeneration
in one transaction. Wait for `ENRICHED` and a changed `generatedAt`, inspect the
revision, then approve with a new action ID. Approval accepts assistance without
closing the ticket or generating another revision. Invalid requests return 400,
unknown tickets return 404, and review conflicts return 409.

## Failure replay

The UI's failure sample uses a `[demo-fail-once]` title prefix to deliberately
exhaust initial processing attempts. Inspect failures before replaying; fix the
cause of unexpected failures first. Replay can call OCI again.

The replay envelope has a new `eventId` and a `causationId` referencing the
original failure. With the default three attempts, the deliberate replay fails
transiently once before succeeding. The original failure leaves the replayable
worklist; repeating replay for the resolved failure returns 404.

## Read paths

Both ticket GET endpoints accept `readPath=primary` or `readPath=cache`.
An omitted or blank value requests cache; other values return 400.
The `X-Read-Path` response header reports `primary`, `true-cache`, or
`primary-fallback`. Fallback means cache access failed and primary served the
request. Cache misses and stale results can occur while redo is applied.

The UI selects a read path for lists and always requests primary for detail and
review screens. Assistance and review history are read from primary.

## Management endpoints

The management server runs at `http://localhost:9002`, separately from the API:

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/actuator/health` | Backend health. |
| GET | `/actuator/metrics` | Available application metrics. |
| GET | `/actuator/metrics/support.ticket.events` | Ticket event metric details. |

Use Grafana for the telemetry walkthrough in the [main guide](README.md).
