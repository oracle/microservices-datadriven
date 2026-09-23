# Customer Support Lab v2 Specification

## Purpose

Evolve the Customer Support Lab from a ticket application with asynchronous
embedding into a production-oriented AI support workflow. The lab should
demonstrate how Oracle AI Database and OCI capabilities address the practical
concerns of an agentic application: reliable event processing, partial
failures, read-heavy workloads, regional data placement, auditable human
approvals, and operational visibility.

MicroTx is explicitly out of scope for this version.

## Starting Point

The existing lab already demonstrates the core data and eventing path:

- Spring Boot REST APIs create and retrieve support tickets.
- TxEventQ, accessed through Apache Kafka APIs, atomically persists a ticket
  and publishes its processing event.
- An asynchronous consumer generates embeddings through OCI Generative AI.
- Oracle AI Vector Search identifies related tickets.
- JSON Relational Duality Views provide an optional JSON-oriented data path.

Version 2 extends these capabilities into an explicit, observable support
workflow. It should retain the existing progressive-profile style so each
technology can be demonstrated in isolation before the complete flow.

## Target Experience

A support agent submits a ticket and immediately receives its identifier and
initial workflow status. Background processing enriches the ticket with an AI
summary, similar historical tickets, and relevant support policies. The agent
can see whether processing is complete, retrying, or awaiting review. Read
traffic can be served through an appropriate cache-aware path, while all
authoritative writes remain on the primary database. Selected data stays in
its assigned region, and sensitive recommendations receive a tamper-evident
human approval record.

The demo should make the operational evidence visible: event latency, retry
behavior, AI-call outcomes, database and cache behavior, and end-to-end traces
from ticket submission through enrichment and approval.

## Functional Scope

### 1. Explicit ticket lifecycle

Tickets have durable workflow state instead of implying that asynchronous work
is complete when the create request returns. The initial set of states is:

- `RECEIVED`
- `TRIAGED`
- `ENRICHED`
- `NEEDS_APPROVAL`
- `RESOLVED`
- `FAILED`

The create API returns the ticket identifier and initial status. Ticket detail
and list views expose the current workflow status and the results that are
available so far.

### 2. Durable ticket-work events

Ticket events use a small, versioned envelope rather than serializing the full
ticket as the event contract. At minimum, the envelope identifies the ticket,
event type, event ID, correlation ID, causation ID, attempt number, and creation
time. Ticket content remains in Oracle AI Database as the source of truth.

This contract supports replay, idempotent consumers, retry diagnostics, and
future workflow stages without coupling every consumer to the ticket schema.

### 3. Reliable asynchronous enrichment

Enrichment is divided into independently reportable steps:

- Generate a concise AI summary.
- Create an embedding.
- Find related historical tickets with vector search.
- Retrieve relevant support policies and runbooks.
- Optionally recommend category, priority, or routing.

Each step records its outcome. Transient failures use bounded retries with
backoff. Exhausted retries and non-retryable failures move the work to a
durable review or failure queue. Operators can inspect and explicitly replay
failed work. Processing must be idempotent so replay does not duplicate ticket
relations, summaries, or approval requests.

### 4. Policy-aware AI assistance

The lab adds a small, curated support-policy corpus alongside ticket vectors.
For a ticket, the application persists structured AI assistance rather than a
single opaque response:

- Summary for a support agent.
- Suggested category and priority, when enabled.
- Similar tickets with relevance scores.
- Relevant policy or runbook references with relevance scores.
- AI model and prompt/version metadata needed to explain the result.

These are recommendations. The lab does not automatically execute external
actions or treat generated output as a final policy decision.

### 5. Read scaling with Oracle True Cache

Read-heavy endpoints, such as ticket lists, ticket detail, and a triage
dashboard, are candidates for a True Cache-aware read path. Only read-only and
freshness-tolerant work may use this path. Ticket creation, workflow updates,
retry bookkeeping, and approvals always use the primary database.

The lab should expose which read path served a request and clearly document the
freshness tradeoff. The exact cache topology and connection configuration remain
environment-specific.

### 6. Regional data placement

Tickets carry a data-residency or assigned-region attribute. A regional data
access layer selects the correct regional service before ticket persistence or
retrieval.

The initial demonstration uses two logical regions. Ticket content, policy
corpora, and approval records remain in the selected region. Any global view is
limited to intentionally approved, minimized operational metadata. The physical
multi-region topology is a deployment decision and is not prescribed by this
application specification.

### 7. Tamper-evident approval history

Sensitive recommendations, such as a proposed customer-impacting action or a
policy exception, can enter `NEEDS_APPROVAL`. A human decision is written to an
Oracle blockchain table with the ticket ID, recommendation, approver, decision,
timestamp, and rationale.

Blockchain tables are reserved for approval evidence, not routine application
logs or every automated workflow transition.

## Observability Scope

Metrics, tracing, logs, and dashboards are part of the lab experience rather
than post-demo infrastructure.

### Metrics

Expose application and database-relevant metrics through Spring Boot Actuator
and Micrometer, with Oracle-capable export/configuration kept as a selectable
environment concern. The initial metric set should cover:

- Ticket lifecycle counts by state and region.
- Event age, consumer lag or backlog, retry count, and review-queue depth.
- Per-enrichment-step duration, success, failure, and retry outcomes.
- OCI Generative AI request count, duration, error class, and rate-limit
  outcomes.
- Vector and policy retrieval result counts and durations.
- Primary-database versus True Cache read routing and cache-path latency.
- Approval volume and time spent awaiting approval.
- JDBC/UCP pool health and database-facing metrics where they are safely
  available.

Metric labels must remain low-cardinality. Ticket IDs, customer identifiers,
full prompts, and ticket text must never become metric labels.

### Distributed tracing

Create an end-to-end trace beginning at ticket submission and continue it
through TxEventQ publication, event consumption, each enrichment step, database
access, OCI Generative AI calls, cache-aware reads, and approval actions.

The event envelope carries the correlation and trace context needed to link the
asynchronous boundary. Spans should identify the operation and outcome but must
not record ticket descriptions, generated summaries, credentials, or other
sensitive content by default. Trace sampling and export destinations are
deployment configuration.

### Structured logs

Use structured logs keyed by correlation ID, ticket ID where appropriate, event
ID, workflow step, attempt number, region, and outcome. Logs complement traces
for diagnosis but must not become a second store of customer ticket content.

### Dashboards

The lab includes high-level dashboard definitions and sample views, without
committing to a single dashboard product in this version. A dashboard may be
implemented in an Oracle observability service, a Prometheus-compatible
dashboard tool, or another environment-standard platform.

The initial dashboard set should include:

- **Workflow overview:** tickets by lifecycle state, throughput, end-to-end
  processing time, and regional distribution.
- **Reliability:** event backlog, retries, review-queue depth, failed steps,
  and replay outcomes.
- **AI quality and cost signals:** model-call volume and latency, error rate,
  related-ticket and policy retrieval counts, and recommendation-to-approval
  funnel.
- **Data and read path:** primary versus cache read volume and latency, pool
  health, and database-facing capacity signals.
- **Approvals:** pending approvals, approval duration, decisions by type, and
  region.

Dashboard data must aggregate or link to governed detail views rather than
displaying ticket text or generated content broadly.

## Progressive Demo Stages

- `events`: atomic ticket submission and TxEventQ-driven asynchronous work.
- `ai`: ticket summaries, embeddings, similar tickets, and policy retrieval.
- `reliability`: workflow state, retries, partial failures, review queue, and
  replay.
- `observability`: metrics, traces, structured logs, and dashboard walkthrough.
- `read-scale`: True Cache-aware read routing and freshness behavior.
- `residency`: regional routing and scoped data visibility.
- `approvals`: blockchain-backed approval history.

Profiles may remain additive, but each stage must work independently with clear
prerequisites and an explicit explanation of what it adds to the story.

## Architectural Principles

- Oracle AI Database is the authoritative system of record for tickets and
  workflow state.
- TxEventQ provides the durable asynchronous boundary; consumers are
  idempotent and retry-aware.
- Keep event contracts small, versioned, and independent of the full ticket
  representation.
- Separate workflow orchestration, persistence, AI clients, retrieval, and
  HTTP presentation into focused components.
- Treat cache reads as an explicit consistency tradeoff, never as a write path.
- Keep regional placement and data-governance decisions visible in the domain
  model and deployment configuration.
- Reserve blockchain tables for high-value, human approval evidence.
- Avoid storing secrets, ticket text, embeddings, prompts, or generated output
  in metrics labels and default trace/log attributes.

## Delivery Sequence

1. Add lifecycle state and the event envelope.
2. Make enrichment steps idempotent; add retry, review-queue, and replay
   behavior.
3. Add summaries and policy-aware retrieval.
4. Add metrics, tracing, structured logs, and high-level dashboard definitions.
5. Add True Cache-aware read routing.
6. Add regional routing.
7. Add blockchain-table approvals.

Each stage should include an isolated demo path, automated tests for its
failure behavior, and a short operator-facing verification guide.

## Deferred Decisions

- The exact OCI Generative AI chat and embedding model choices.
- The concrete retry schedule, retention period, and failure-queue operation
  model.
- The dashboard product and telemetry export destination.
- The physical True Cache and multi-region deployment topology.
- The policy-corpus source, update process, and access-control model.
- Approval roles, authentication, and authorization integration.
- Any MicroTx-based cross-boundary workflow coordination.
