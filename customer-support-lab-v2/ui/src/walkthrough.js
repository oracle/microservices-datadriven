// Chapters follow the README's UI workflow. Navigation never submits work.
export const walkthrough = [
  {
    id: "ready",
    title: "Meet the lab",
    short: "Start here",
    animation: {
      title: "Complete event loop",
      file: "/diagrams/14-complete-event-loop.svg",
      alt: "Animated overview of ticket submission, AI enrichment, review, feedback, and replay.",
    },
    summary:
      "One request connects a Vue console, Spring Boot, Oracle AI Database, OCI Generative AI, True Cache, and Grafana.",
    steps: [
      "Start Compose, then Maven. Start the UI separately with npm.",
      "At AI startup, three seeded support policies and three synthetic resolved reference tickets receive 1536-dimensional embeddings before the consumer subscribes to ticket_event.",
      "Follow the chapters from left to right. Each chapter has its own tools below the instructions; results refresh here as you work.",
    ],
    mechanism:
      "TxEventQ lives inside Oracle AI Database. OKafka is its Kafka-style Java API; this lab has no separate Kafka broker. The event consumer runs inside the Spring Boot process.",
    evidence:
      "The inventory below shows current table counts, configured models, and policy indexing. Table counts and indexing status do not establish external service health.",
    practice: "Check your starting point",
    // PolicyIndex.run → OKafkaManager.init
    pseudocode: `on Spring Boot startup:
  for policies and resolved reference tickets missing embeddings:
    vectors = OCI.embed(reference text)
    require vectors have 1536 dimensions
    save vectors in Oracle; commit

on application ready:
  ensure TxEventQ topic "ticket_event" exists
  start background OKafka consumer in this process
  subscribe to "ticket_event" with manual acknowledgement

Vue console → Spring Boot API → Oracle AI Database`,
    actions: [],
  },
  {
    id: "submit",
    practice: "Publish a ticket, then follow its progress",
    title: "Submit a request",
    short: "Submit",
    animation: {
      title: "Atomic ticket publication",
      file: "/diagrams/02-transaction-boundaries.svg",
      alt: "Animated transaction boundaries showing the ticket and event committed together, followed by the consumer outcome and queue acknowledgement.",
    },
    summary: "Create a ticket and publish its work event in one transaction.",
    // TicketEventProducer.submit
    pseudocode: `on publishTicket(title, description, optional correlationId):
  begin OKafka producer transaction
  connection = producer.getDBConnection()
  ticketId = insert support_ticket(title, description, RECEIVED)
             using connection
  event = submitted(ticketId, correlationId or new UUID)
  // Envelope: event ID, ticket ID, type, timestamp; no ticket text
  inject trace context into event and message headers
  send event to "ticket_event"
  commit ticket + event together; return ticketId
  on error: abort transaction`,
    steps: [
      "Use the MFA sample below. Read or edit the title and description; leave the optional correlation ID blank.",
      "Click Publish ticket event, then View ticket in the receipt. This creates a real ticket and can call OCI.",
      "Watch the ticket move from RECEIVED to ENRICHED. Live refresh polls every five seconds; Refresh checks immediately.",
    ],
    mechanism:
      "Spring Boot commits support_ticket and the TxEventQ event together. The envelope carries IDs, timestamps, and trace context; the ticket text stays in the database.",
    evidence:
      "The publication receipt includes the ticket ID. Inspect the ticket below for workflow status and saved assistance. TRIAGED identifies imported reference cases; FAILED means continue to the Recover chapter.",
    actions: [
      {
        label: "MFA sample",
        tab: "samples",
        preset: "mfa",
      },
      { label: "Tickets", tab: "tickets", readPath: "primary" },
    ],
  },
  {
    id: "enrich",
    practice: "Compare similar problems",
    title: "Follow AI enrichment",
    short: "Enrich",
    animation: {
      title: "AI enrichment and vector search",
      file: "/diagrams/04-ai-and-vector-search.svg",
      alt: "Animated flow from ticket text through OCI Generative AI and Oracle vector search to saved assistance and scored matches.",
    },
    summary:
      "See how AI enrichment uses retrieved evidence to suggest different next steps for two sign-in problems.",
    // TicketEventConsumer.processRecord → GenAIEventProcessor → TicketSummarizer
    pseudocode: `on consume(event):
  if event already has an outcome: acknowledge; skip
  validate event; load ticket; set TRIAGED in this transaction
  vector = OCI.embed(title + description + reviewer feedback)
  related = Oracle.cosineSearch(tickets excluding self, vector,
                               minScore=0.2, limit=5)
  policies = Oracle.cosineSearch(policies, vector, minScore=0.2, limit=3)
  previous = saved assistance if this is a feedback event
  draft = OCI.chat(ticket, policies, related recorded resolutions,
                   previous, accumulated feedback)
  require summary + suggested resolution; validate suggested source IDs
  save vector, ENRICHED, draft, scores, model + prompt version
  mark event processed
  commit saved results + queue acknowledgement together`,
    steps: [
      "Choose Saved assistance and select the ENRICHED Lost MFA authenticator ticket from Submit. Inspect its summary, suggested resolution, policy matches, and related tickets. Expand a recorded resolution to see the historical evidence.",
      "Choose Sample requests below, select Account access, and publish it. This request has working MFA but a possible account or tenant mismatch. Wait for ENRICHED.",
      "Return to Saved assistance and switch between the two tickets. Compare their request details, matched policies, recorded resolutions, and suggested next steps. Does the assistance distinguish a lost MFA factor from the wrong account or tenant?",
      "Check the source citations, similarity scores, model, prompt version, and generation time. Scores measure relevance, not confidence; only related tickets with recorded resolutions supply historical resolution examples.",
      "For another contrast, publish Billing dispute to inspect a human-review recommendation, or Outside the policy corpus to explore how the assistance handles missing evidence.",
    ],
    mechanism:
      "OCI creates the embedding; Oracle performs exact cosine retrieval against tickets and policies. One chat call uses the ticket, retrieved policy bodies, and recorded resolutions from similar tickets to generate a summary and suggested next steps with source references. Unresolved descriptions and earlier AI suggestions are not proven fixes. Results, the processed event ID, and queue acknowledgement commit together.",
    evidence:
      "Look for next steps grounded in each request’s retrieved evidence: verified recovery for lost MFA, and account or tenant checks when MFA still works. Three synthetic resolved reference tickets provide historical examples. Earlier AI suggestions are not proven fixes. The application generates assistance; it does not change accounts or issue refunds.",
    actions: [
      {
        label: "Saved assistance",
        tab: "tickets",
        readPath: "primary",
      },
      {
        label: "Sample requests",
        tab: "samples",
        preset: "mfa",
      },
    ],
  },
  {
    id: "review",
    practice: "Revise and approve saved assistance",
    title: "Revise, then approve",
    short: "Review",
    animation: {
      title: "Human review and blockchain history",
      file: "/diagrams/08-blockchain-reviews.svg",
      alt: "Animated flow from saved AI assistance through human review to blockchain history, with feedback requesting a revised summary.",
    },
    summary:
      "Human feedback returns through the event loop; each reviewed version is preserved.",
    // TicketReviewService.recordReview → TicketApprovalStore.record
    pseudocode: `on review(ticketId, actionId, reviewer, decision, reason):
  begin OKafka producer transaction; lock ticket
  if actionId already recorded:
    require same review; commit; return saved review
  require ENRICHED ticket with saved assistance
  append blockchain review snapshot:
    assistance, SHA256(assistance), reviewer, decision, reason,
    model, prompt version
  if decision == REJECTED:
    append feedback; set ticket RECEIVED
    publish feedback event → normal enrichment with previous assistance
  commit snapshot + feedback + any event together
  on error: abort transaction
  // APPROVED saves the snapshot without regenerating or closing the ticket`,
    steps: [
      "In the review workspace below, select an enriched ticket and enter a reviewer ID, such as demo-reviewer.",
      "Choose Request revision. Enter: “The affected account belongs to the test tenant. Include that context in the summary.” Then click Send feedback & regenerate.",
      "Wait for ENRICHED and a new generation timestamp. Compare the feedback with the revised summary, then choose Approve and click Approve assistance.",
      "After approval, the workspace moves to the next pending ticket. Switch the list filter to All tickets to revisit the approved ticket and inspect both review snapshots.",
    ],
    mechanism:
      "A rejection saves a blockchain review snapshot, appends feedback, and publishes regeneration in one transaction. Revision prompts include previous assistance and accumulated feedback. Approval preserves another snapshot and accepts the current assistance without publishing a regeneration event.",
    evidence:
      "Review history preserves the earlier and revised summaries and suggested resolutions, reviewer IDs, decisions, and SHA-256 assistance digests. Oracle V2 blockchain row chaining protects the history. Approval accepts assistance; it does not resolve or close the ticket.",
    actions: [{ label: "Human Review", tab: "review" }],
  },
  {
    id: "recover",
    practice: "Create a failure, replay it, and inspect the result",
    title: "Recover a failed event",
    short: "Recover",
    animation: {
      title: "Retries and manual replay",
      file: "/diagrams/03-retry-and-replay.svg",
      alt: "Animated flow showing bounded processing attempts, durable success or failure, acknowledgement, and manual replay with a new event ID.",
    },
    summary:
      "Deliberately fail an event, inspect the durable worklist, and replay the work.",
    // TicketEventConsumer.processRecord, DemoFailureInjector, TicketEventProducer.replay
    pseudocode: `on processing failure:
  roll back attempt to savepoint
  retry transient errors with exponential backoff (default: 3 attempts)
  if non-retryable or attempts exhausted:
    save FAILED + event envelope, attempt count, error type
    commit failure + queue acknowledgement together

on replay(failedEventId), in one producer transaction:
  lock original failure; require replayable envelope
  replay = original with new event ID and causationId = original.eventId
  mark original replayed; reset FAILED ticket to RECEIVED
  publish replay; commit; on error: abort
  // Normal consumer processes the new event

// [demo-fail-once]: original fails without retry;
// replay fails transiently on attempt 1, then enriches on attempt 2`,
    steps: [
      "Open the failure sample below and keep the [demo-fail-once] title prefix. Publish the ticket.",
      "Wait for FAILED, then choose Failed Events below. Inspect the error, attempt metadata, and replayable event ID.",
      "Click Replay event. The new event is linked to the original failure by its causation ID. With the default three attempts, replay fails transiently once before succeeding.",
      "Choose the ticket panel below and confirm ENRICHED. The original failure leaves the active worklist and remains recorded as replayed.",
    ],
    mechanism:
      "A failed delivery stores failure metadata. Replay publishes a new event, so the normal consumer and retry path process it again. For an unexpected failure, fix its cause before replaying; OCI may be called again.",
    evidence:
      "Use the UI worklist for current replayable failures. A rolling Grafana failure count can remain positive after successful recovery because it still includes the earlier failure.",
    actions: [
      {
        label: "Failure sample",
        tab: "samples",
        preset: "failure",
      },
      { label: "Failed Events", tab: "failures" },
    ],
  },
  {
    id: "cache",
    practice: "Compare primary and True Cache reads",
    title: "Compare the read paths",
    short: "Cache",
    animation: {
      title: "Primary and True Cache reads",
      file: "/diagrams/05-true-cache.svg",
      alt: "Animated comparison of primary and True Cache reads, with redo replication and a primary fallback when the cache is unavailable.",
    },
    summary:
      "Read the ticket list through True Cache while keeping detail and review reads fresh.",
    // TicketReadRouter.route; UI detail and review requests explicitly use primary
    pseudocode: `on GET /tickets?readPath=primary:
  return primary.listTickets(), X-Read-Path: "primary"

on GET /tickets?readPath=cache:
  try:
    return trueCache.listTickets(), X-Read-Path: "true-cache"
  catch CacheUnavailable:
    return primary.listTickets(), X-Read-Path: "primary-fallback"

// True Cache applies committed primary changes through redo; reads may lag
UI ticket detail + review → primary
all writes → primary
record actual read path, outcome, and latency`,
    steps: [
      "Choose Primary ticket list below and note the ticket IDs and statuses.",
      "Switch Ticket list read path to True Cache · cache. Check Served by: true-cache confirms the cache served the list.",
      "If you see primary-fallback, the primary served the request because cache access failed. That does not prove a successful cache read.",
      "New tickets and statuses may lag while redo is applied. Switch back to Primary · fresh when checking the latest state. Detail and review screens always read primary.",
    ],
    mechanism:
      "True Cache is a read-only Oracle cache that follows committed changes through redo. It provides an alternate ticket-list read path; it is not a separate owner of workflow state.",
    evidence:
      "Compare the reported Served by value with the requested read path. A cache hit can be stale; primary-fallback is a different outcome. The snapshot below reports the last list read.",
    actions: [
      { label: "Primary ticket list", tab: "tickets", readPath: "primary" },
      { label: "True Cache ticket list", tab: "tickets", readPath: "cache" },
    ],
  },
  {
    id: "observe",
    practice: "Follow your work into Grafana",
    title: "Connect the telemetry",
    short: "Observe",
    animation: {
      title: "Telemetry into Grafana",
      file: "/diagrams/06-observability.svg",
      alt: "Animated flow from Spring Boot through OTLP export to Grafana LGTM for correlated metrics, traces, and logs.",
    },
    summary:
      "Follow the same work through traces, event metrics, retries, and connection pool activity.",
    // TicketTelemetry, EventTraceContext, application.yaml, exporter/config.yaml
    pseudocode: `on submit / review / replay: start operation observation
on publish: inject traceparent + tracestate into headers and envelope
on consume: restore trace context; start consumer observation
  observe embedding, retrieval, generation, persistence
  record retry count as retries occur
  after queue commit: count outcome; record processing time + event age
  log event ID, correlation ID, ticket ID with trace context

Spring Boot → OTLP traces, metrics (every 5s), logs → LGTM
Oracle Database Exporter → primary + True Cache metrics (every 15s)
Grafana → Prometheus metrics, Tempo traces, Loki logs`,
    steps: [
      "Generate tickets, feedback, and a replay using the earlier chapters. Allow several five-second metric export intervals.",
      "Open Grafana → Oracle AI Database → Customer Support Workflow. Inspect event outcomes, retry attempts, processing time, and read paths.",
      "Open Oracle UCP Metrics to inspect pool usage and connection acquisition activity.",
      "Open Oracle Database Health to compare primary and True Cache sessions, waits, CPU, memory, and I/O. Check cache lag together with the age of its statistics.",
      "In Explore, select Tempo and search service customer-support-lab-v2. Follow HTTP, publication, consumption, AI, feedback, replay, and JDBC spans.",
    ],
    mechanism:
      "Spring Boot exports OpenTelemetry traces, metrics, and logs to LGTM. The database exporter separately queries the primary and True Cache every fifteen seconds. Trace context travels with the event envelope so work can be correlated across the asynchronous handoff.",
    evidence:
      "The rolling failure count estimates failures in a window; it is not the current worklist. In Grafana Explore, select Loki and query {service_name=\"customer-support-lab-v2\"} for application logs. Console logs also remain in the Maven terminal.",
    actions: [{ label: "Open Grafana", external: true }],
  },
];
