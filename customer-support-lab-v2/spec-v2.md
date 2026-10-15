# Customer Support Lab v2: Simpler, More Teachable

## Goal

Teach one support-ticket story that can be run twice without repair: create a
ticket, process its TxEventQ event, deliberately fail one event, inspect the
durable failure, and replay it successfully. The standard stack includes
True Cache so the same lab also demonstrates a primary read and a cache read.
AI assistance and observability extend that story in short optional chapters.

This is a clean-slate lab: no schema migrations, old event formats, or
backwards-compatibility paths. Database SQL assumes a fresh Compose startup:
create the user, grants, and tables without restart, repair, or validation
guards. Only application restarts are part of the lab workflow. An optional
blockchain chapter records human
reviews of saved AI summaries. Regional placement is a documented deployment
concept, and MicroTx is mentioned as a future avenue for workflows across
transaction boundaries. Neither is installed by this lab. The local APIs
are unauthenticated
and must not be presented as production-secure. AI results are recommendations,
never automatic customer-impacting actions.

## The smallest useful lab

| Layer | Keep for the core | Add only in its chapter |
| --- | --- | --- |
| Runtime | Maven-run Spring Boot app plus the full Compose stack: primary, True Cache, registration helper, and LGTM | OCI Generative AI configuration |
| Data | One SQL ticket path and two small event-outcome tables | Curated policies, assistance, and scored links |
| Workflow | Submit → `RECEIVED` → `TRIAGED`; fail → `FAILED` → replay | `ENRICHED` when AI is enabled |
| Learner actions | Start, set up schema, run one replay script that also checks both read paths | One script and one expected observation per optional chapter |

Use `docker compose up -d` for the full topology. True Cache is not a profile
or an alternative route; its readiness and primary-side registration are part
of a successful lab start. OCI credentials are not needed for the core story.
Keep one ticket
example across the README, scripts, dashboard, and optional chapters. Put
connection variants and tuning after the walkthrough, not before it.

## Design rules

- One ticket writer, one read API, one SQL ticket store, two work event types, and
  one consumer flow. Do not restore a parallel JSON duality/ORDS writer or
  add a framework for branching demo scripts.
- The event envelope contains only ticket ID, event ID, correlation ID,
  optional causation ID, creation time, and trace context. Ticket text remains
  in the database. Java uses `UUID`; JDBC binds event IDs as 16-byte `RAW`;
  HTTP and OSON stringify only at their boundaries.
- Ticket states are `RECEIVED`, `TRIAGED`, `ENRICHED`, and `FAILED`. `REPLAYED`
  describes an event outcome, not a ticket state. Human reviews append to a
  separate optional blockchain history. Approval accepts the saved summary;
  rejection appends required feedback to the ticket, resets it to `RECEIVED`,
  and publishes `TICKET_FEEDBACK_SUBMITTED` in the same transaction. The AI
  consumer regenerates its summary, embedding, and matches, returning it to
  `ENRICHED`. Reviews do not execute customer actions. Resolution states remain
  out of scope.
- Preserve atomic ticket/event submission, idempotent processing, bounded
  retries, a durable failed-event worklist, and explicit replay. Replay
  publishes a new event linked to the original; a redelivered original must
  not reopen a replayed failure. Do not imply exactly-once external AI calls.
- Prefer clear relational links to JSON blobs introduced merely to lower the
  table count. Keep the processed-event idempotency key set separate from the
  failed-event worklist unless a single table demonstrably simplifies both
  transactions and queries.
- Cache reads are explicitly freshness-tolerant. Writes, replay, assistance,
  and fresh reads stay on the primary. `X-Read-Path` must describe the actual
  path, including fallback; a fallback is not proof of a cache read.
- Metrics use bounded labels. Do not put ticket text, prompts, summaries,
  customer data, secrets, or ticket/event IDs in metric labels. Do not claim
  logs, traces, or dashboard signals that have not been observed end to end.

## Staged work from the current implementation

### 1. Make the full-stack orientation predictable

Keep the README's single `Start here` route and make its first screen answer:
what runs, what credentials are needed, which health and registration checks
prove True Cache is ready, what command demonstrates success, and how to
repeat it. Keep one full-stack Compose command.
Measure the complete path with warm and uncached dependencies; distinguish
host-dependent timings from a guarantee. Move profile/port/wallet variants
into a compact reference.

**Gate:** a fresh learner can replay a ticket without OCI credentials and
prove that same ticket is read from True Cache, with no manual database repair.

### 2. Make the core code and schema explain themselves

The parallel writer and duality path are already gone. Now review naming and
transaction boundaries in the ticket producer, consumer, outcome store, and
replay endpoint. Keep the fail-once injector visibly demo-only. Remove unused
configuration, wrappers, and state only when their callers and tests move.
Assess the seven tables by purpose, not by chasing a smaller number: ticket;
processed event; failed event; and, for AI, policy, assistance, related ticket,
and policy match. Keep the two event tables if merging them would obscure
idempotency or replay. Keep the two scored-link tables if the demo displays
their relationships. Maintain one clean-slate `init`, `truncate`, and
`cleanup` schema set; do not add migrations.

The small ticket dataset uses exact `VECTOR_DISTANCE` scoring; an IVF index
would add setup work without a read-scale lesson. Add one only if a later lab
actually demonstrates approximate search and its accuracy trade-off.

**Gate:** normal submission, duplicate delivery, exhausted retries, invalid
replay, repeated replay, and a redelivered original have clear outcomes and
focused tests. A second live walkthrough needs no database repair.

### 3. Keep AI to one visible assistance result

With the `ai` profile, enrich the same ticket with one concise summary, a few
similar tickets, and cited/scored policy matches. Reuse the Spring AI Oracle
model integration and the small seeded policy corpus. Expose model and prompt
version for explanation, but do not save every intermediate model artifact or
add category/priority predictions that the lab does not evaluate. Policy
indexing should not block non-AI startup. Make a failed model call visible in
the same replay worklist; explain that replay may repeat a chargeable call.

**Gate:** one AI ticket reaches `ENRICHED` with persisted, readable references;
one model failure is replayable; the no-AI path is unchanged. Verify the full
AI event path against an authorized OCI model before claiming it is live.

### 4. Show operational evidence for the standard cache path

Use a small dashboard for event outcomes/retries, a rolling-window failure
gauge, processing latency, and served read paths. The application emits
time series from event handling; metric collection must not run ticket-count
queries. Grafana computes recent failures from the failure counter, with a
default five-minute window and a red threshold of five. Show one correlated
HTTP → event-consumer → JDBC trace, plus useful Oracle JDBC/UCP signals.
Only add log panels after application logs are actually delivered to LGTM.
Avoid placeholder consumer-lag, OCI-cost, regional, or approval panels.

Demonstrate a fresh primary read, a cache-tolerant read, and
an unavailable-cache fallback. Verify actual cache identity before labeling a
response `true-cache`. Keep the current separate read-only pool until a live
comparison proves that one driver-routed datasource simplifies the code **and**
preserves cache routing, primary writes, pooled read-only reset, and fallback.
Do not change topology based on static configuration alone.

**Gate:** the named dashboard panels and trace contain real data; a live
`X-Read-Path: true-cache` response reaches the cache. Fallback is a useful
resilience observation, not a substitute for the required cache demo.

### 5. Rehearse and trim the teaching flow

Each optional chapter gets a prerequisite, one command, expected output, a
failure explanation, and a reset/next-step instruction. Keep separate small
scripts rather than a menu-driven demo framework. Re-run the README from a
clean schema, then repeat it without clearing data. Fix any step that requires
unexplained SQL, hidden environment variables, or manual repair. Clearly
separate static checks, local database verification, live cache routing, live
OCI calls, and observability delivery in the final report.

**Gate:** another person can run the guided sequence twice and explain what
each moving part adds to the original ticket story.

## Current evidence and open gates (2026-09-30)

The current tree has 33 main Java files, 28 test files, seven tables, and one
SQL ticket path. Earlier Oracle-primary validation completed fail/replay twice
without repair; Oracle smoke tests covered 16-byte event IDs, event outcomes,
AI vector persistence, and rollback. The latest local test reports show 68
passed, two opt-in smoke tests skipped, and no failures (70 total). The two
smoke tests were also run separately against a disposable Oracle instance.
The documented full Compose file passes `docker compose config --quiet`, and
the former shell bootstrap accepted the README's environment contract
without exposing either password. It has since been replaced by the directly
mounted `db/init.sql` startup hook. `mvn package` also passes and produces an
executable Spring Boot JAR. A fresh full Compose start subsequently brought up
healthy primary and True Cache databases, healthy LGTM, and a registration
helper that exited successfully. The Maven app started with
`events,demo-failures,observability`; the clean schema setup created its seven
tables and three seeded policies.
With images and Maven dependencies already cached, a fresh primary-plus-LGTM
run reached its first replay result in 104 seconds, including operator pauses;
this is not an uncached-startup promise. The README now starts the full Compose topology;
True Cache reads are configured in the base app rather than a `read-scale`
profile. An application-profile test verifies OTLP export is off without the
optional observability profile and on with it. The revised full-stack route
has not been benchmarked as a startup-time claim. A focused Spring context
test confirms the base profile constructs a lazy True Cache UCP reader without
connecting. The replay script invokes the cache check for its own ticket and
displays both workflow statuses without requiring them to match. Live runs for
tickets 1 and 2 both passed failure → replay → `TRIAGED`, rejected a repeated
replay, and returned HTTP 200 with `X-Read-Path: true-cache` for the same
ticket. The second run reused the schema without repair.

Ticket insertion and replay's conditional status reset now live in
`TicketStore`; both still use the OKafka producer connection before the event
commit. Focused tests assert the producer's transaction order and the store's
JDBC binds and update count. Producer telemetry now runs after commit and
cannot turn a committed submission or replay into an apparent failure; tests
also verify that an abort error does not mask the original transaction error.
The consumer likewise treats post-acknowledgment telemetry failures as
non-transactional while propagating a failed `commitSync()`; both paths have
focused tests. This does not resolve an ambiguous database commit response.
The demo-only failure path now makes the replayed event fail transiently on
its first attempt and succeed on retry; when retries are configured off, it
skips that injection. Focused tests cover both paths. Both live replay runs
logged one transient retry, and the exported retry counter reached two.
AI step, retry, and match telemetry is now best-effort: a metric or observation
failure does not turn completed model work into a replayable processing failure
or mask the actual work exception. Focused tests cover metric failure paths.
Similar-ticket retrieval keeps the SQL score order in a list, without a
deduplication set.
Its two-field result is an immutable record like policy matches; focused tests
cover ranking, vector
binding, and the unchanged JSON field names. The small policy corpus remains
an exact scan.
The unused IVF index and annotation are gone from the clean-slate schema;
vector columns and cosine scoring remain.
The core ticket model no longer defines unused ID-based equality, which also
avoids treating two unsaved null-ID tickets as equal; its text-safe `toString`
and JSON fields are unchanged.

LGTM received workflow metrics and an HTTP → consumer → JDBC trace. App logs
are not forwarded to LGTM. The dashboard now includes a served-read-path panel;
router tests verify the `primary`, `true-cache`, and `primary-fallback` metric
labels. In the earlier full-stack run, all six original dashboard expressions
returned live Prometheus data: two `TRIAGED` tickets, an empty final worklist,
failed and processed event counters, retries, processing time, and both
`primary` and `true-cache` reads. Tempo returned one trace containing
`http post /tickets`, `support.ticket.consume`, and `Execute query` spans.
The dashboard does not render synthetic zeroes for missing telemetry or retry
metrics. Read metrics fail open so instrumentation cannot convert a successful
GET into an error or hide the real read exception; focused tests cover both
outcomes. Stopping this lab's cache yielded HTTP 200 with
`X-Read-Path: primary-fallback`. After restart, the inherited `FREEPDB1_TC`
service definition was present but inactive; an idempotent extension of the
existing registration helper now starts it. Recreating that helper restored
`X-Read-Path: true-cache` for the same ticket. This recovery path was tested
both when the service was already active and when it was stopped.

The full AI event flow was live-validated on 2026-10-06 with all four profiles:
`events,ai,demo-failures,observability`. OCI FILE authentication in
`us-chicago-1` used `cohere.command-a-03-2025` (temperature 0.2, maximum 512
tokens) and `cohere.embed-v4.0` with 1536 dimensions. The lab explicitly
includes the OCI SDK Jersey 3 HTTP transport required for AI startup.
All 70 tests passed, including both live Oracle persistence smoke tests.
Two AI walkthroughs and the failure/replay walkthrough produced three
`ENRICHED` tickets with saved summaries and policy matches; the second AI
ticket also retrieved a related ticket. Replay retried once, repeated replay
returned HTTP 404, and primary and True Cache served the same enriched ticket.
Database checks confirmed 1536-dimensional ticket and policy vectors, three
processed events, one `REPLAYED` failure, 16-byte event IDs, and no ready queue
messages. All six dashboard expressions returned Prometheus data. Exported
counters recorded three processed events, one failure, and one retry.
Tempo returned a 14-span trace connecting HTTP submission to the consumer,
embedding, chat, and JDBC work; the consumer's parent span matched the HTTP
span. AI span attributes confirmed the requested models and generation settings.
The AI walkthrough rejects an `ENRICHED` ticket if its saved summary,
model/prompt metadata, or policy matches are missing; local HTTP fixtures also
exercised acceptance and rejection.
The AI and replay scripts now stop promptly with a profile hint when a newly
created ticket completes without the expected AI or deliberate failure;
local response fixtures exercised both wrong-profile paths.

Regional placement remains a descriptor, with no physical multi-region topology.
The optional `events,ai,blockchain` chapter uses a Compose-bootstrapped V2
blockchain table to preserve human decisions, summary snapshots, SHA-256
summary digests, model/prompt metadata, and self-declared reviewer names.
An action UUID deduplicates retries; corrections append a new action.
Rejected reviews also request summary regeneration through TxEventQ. Current
assistance is replaced on success; reviewed snapshots remain in blockchain
history. This extension has automated tests and a runnable HTTP walkthrough in
`scripts/demo-human-feedback.sh`; earlier live validation results above do not
cover the feedback workflow.
Production authentication, cross-service transactions, production retention,
and cache freshness SLOs remain later work.
