// Metadata from the accessible titles and descriptions of the bundled SVGs.
export const diagrams = [
  {
    id: 1,
    file: "/diagrams/01-workflow.svg",
    title: "One ticket, durable work",
    description:
      "Overview: Spring Boot submits tickets and events in one Oracle transaction; the consumer processes TxEventQ events. OKafka uses Kafka APIs without a separate Kafka broker. AI enriches every ticket.",
    category: "Workflow",
  },
  {
    id: 2,
    file: "/diagrams/02-transaction-boundaries.svg",
    title: "Two commits, one database",
    description:
      "The producer atomically commits the ticket and event. In a separate transaction, the consumer commits its database outcome and queue acknowledgement. External OCI calls are outside these database atomicity guarantees.",
    category: "Workflow",
  },
  {
    id: 3,
    file: "/diagrams/03-retry-and-replay.svg",
    title: "Failure is a recoverable state",
    description:
      "Retryable failures roll back attempt writes to a savepoint. Success or durable failure commits with acknowledgement. Replay marks the failure replayed and publishes a new event atomically; causation links the old event. OCI calls may repeat.",
    category: "Workflow",
  },
  {
    id: 4,
    file: "/diagrams/04-ai-and-vector-search.svg",
    title: "AI assistance for human review",
    description:
      "The processor calls OCI for an embedding, runs exact cosine vector search in Oracle for related tickets and policies, generates a summary from the ticket text alone, then saves assistance and ENRICHED status. Matches are for human review, not chat prompt context.",
    category: "Workflow",
  },
  {
    id: 5,
    file: "/diagrams/05-true-cache.svg",
    title: "Offload freshness-tolerant reads",
    description:
      "Oracle primary redo feeds True Cache. The walkthrough lets you select primary or True Cache for the ticket list. Cached reads can lag committed writes. Detail and review screens read primary; cache unavailability falls back to primary.",
    category: "Workflow",
  },
  {
    id: 6,
    file: "/diagrams/06-observability.svg",
    title: "See outcomes and read paths",
    description:
      "The application sends metrics, traces, and logs over OTLP to Grafana LGTM. Workflow and UCP dashboards expose outcomes and read paths. The OpenTelemetry Logback appender exports application logs to Loki with trace and span context; JDBC tracing does not guarantee all OKafka internal spans.",
    category: "Workflow",
  },
  {
    id: 7,
    file: "/diagrams/07-session-alignment.svg",
    title: "The session goes further",
    description:
      "Session scope comparison, not an architecture claim. Regional placement is a deployment concept; MicroTx remains future work. The concurrently added blockchain chapter records human reviews of saved summaries. The lab demonstrates reliability mechanisms but is not production-secure.",
    category: "Workflow",
  },
  {
    id: 8,
    file: "/diagrams/08-blockchain-reviews.svg",
    title: "Preserve the human decision",
    description:
      "Human review preserves the saved summary in blockchain history. Approval accepts the summary. Rejection requires feedback, appends it to the ticket, resets its status to RECEIVED, and publishes TICKET_FEEDBACK_SUBMITTED using the same OKafka transaction. The AI consumer regenerates the summary, embedding, and matches, returning the ticket to ENRICHED. Duplicate review actions do not publish again. Actor identity is supplied by the caller, not authenticated. Reviews do not execute customer actions.",
    category: "Workflow",
  },
  {
    id: 9,
    file: "/diagrams/09-schema-overview.svg",
    title: "Eight tables, one ticket workflow",
    description:
      "Eight application tables from db/init.sql, grouped by their consuming features. All tables are created at database bootstrap. Core processing uses support_ticket, ticket_event_processed, and failed_ticket_event. AI uses support_policy, ticket_assistance, related_ticket, and ticket_policy_match. Blockchain review uses ticket_approval_history. TxEventQ backing objects are prepared separately by the application.",
    category: "Schema",
  },
  {
    id: 10,
    file: "/diagrams/10-schema-event-outcomes.svg",
    title: "A ticket and its event outcomes",
    description:
      "support_ticket stores the business record with RECEIVED, TRIAGED, ENRICHED, or FAILED status and an optional 1536-dimensional FLOAT32 vector. ticket_event_processed records successful event UUIDs. failed_ticket_event records failed envelopes, attempts, failure type and FAILED or REPLAYED state. Arrows here show application associations, not declared foreign keys; both event tables allow nullable ticket IDs without foreign keys. The consumer checks both outcome tables to suppress duplicates, and commits the ticket changes, event outcome, and queue acknowledgement in one transaction.",
    category: "Schema",
  },
  {
    id: 11,
    file: "/diagrams/11-schema-ai-relationships.svg",
    title: "Save AI results beside the ticket",
    description:
      "AI schema relationships from db/init.sql. One ticket can own zero or one ticket_assistance row and zero or many related_ticket and ticket_policy_match rows. A policy can be referenced by zero or many ticket_policy_match rows. ticket_assistance stores a summary, summary_model, prompt_version, and generated_at. Composite primary keys prevent duplicate matches. The related column stores the matched ticket ID but does not have a foreign key. Both embedding columns are VECTOR(1536, FLOAT32). PolicyIndex fills missing policy vectors at AI startup; matches and assistance are saved with the ticket enrichment transaction. Rejected reviews append feedback to the ticket and request regeneration through TxEventQ. The current assistance and scored matches are replaced on regeneration; reviewed snapshots stay in blockchain history.",
    category: "Schema",
  },
  {
    id: 12,
    file: "/diagrams/12-schema-replay.svg",
    title: "Replay preserves the failure record",
    description:
      "Replay locks failed_ticket_event A while its status is FAILED, marks it REPLAYED, resets the same support_ticket from FAILED to RECEIVED, and publishes event B in one producer transaction. The new event has a new UUID, causation_id A, and the original correlation_id. The dashed card represents a queue event, not another application table. The original failure remains recorded and continues to suppress duplicate delivery of A. If B fails, it gets its own failure row.",
    category: "Schema",
  },
  {
    id: 13,
    file: "/diagrams/13-schema-approval-history.svg",
    title: "Keep the exact summary reviewed",
    description:
      "ticket_approval_history is an Oracle V2 blockchain table. It has a primary key action_id and a foreign key to support_ticket.id. The application requires saved assistance for an ENRICHED ticket and copies the summary, chat model and prompt version into the review record. The dashed arrow is an application-level copy, not a foreign key to ticket_assistance. The summary_digest is application-computed SHA-256; blockchain row hashing separately uses SHA2-512. Reviews store actor ID, reason, APPROVED or REJECTED decision, and UTC decision time. Rows have 16-day retention and the table allows deliberate lab drop with zero idle days. Approval leaves ticket workflow status ENRICHED. Rejection appends feedback to support_ticket.review_feedback, resets status to RECEIVED and requests regeneration through TxEventQ, atomically with this review. No review executes customer actions.",
    category: "Schema",
  },
  {
    id: 14,
    file: "/diagrams/14-complete-event-loop.svg",
    title: "One ticket, a complete event loop",
    description:
      "The complete ticket workflow. TicketEventProducer atomically inserts a RECEIVED ticket and publishes TICKET_SUBMITTED to the ticket_event topic in Oracle TxEventQ. The AI consumer embeds the ticket, finds related tickets and policies, generates a summary, and commits ENRICHED assistance, event outcome, and queue acknowledgement together. Human review preserves the reviewed summary in blockchain history. APPROVED keeps the summary without generating another event or resolving the ticket. REJECTED requires written feedback: the dedicated feedback producer atomically saves the review, appends feedback to the ticket, resets it to RECEIVED, and publishes TICKET_FEEDBACK_SUBMITTED. The same consumer regenerates assistance using the previous summary and accumulated feedback. Both producer instances use the same configuration but own separate transaction connections. After bounded retries, or immediately for a nonretryable error, the consumer records FAILED and acknowledges the event; failed_ticket_event is a failure worklist, not a queue. Manual replay marks the original failure REPLAYED, resets the ticket, and publishes a new event preserving its type and causation. Each new published event has its own UUID; redelivered IDs with durable outcomes are skipped. Main coral arrows show normal delivery and the review loop; dashed arrows show failure and manual replay. All labels and arrows are visible without animation.",
    category: "Workflow",
  },
  {
    id: 15,
    file: "/diagrams/context/blockchain-approval-history.svg",
    title: "Blockchain approval history",
    description:
      "A saved AI summary is reviewed by a human. The approval or rejection is appended to an Oracle blockchain table with a summary snapshot, digest, self-declared reviewer, and model metadata. Retry requests reuse the action UUID. A rejected review saves corrections on the ticket and requests regeneration through TxEventQ. Approval accepts the saved summary. The lab does not execute customer actions.",
    category: "Context",
  },
  {
    id: 16,
    file: "/diagrams/context/regional-data-placement.svg",
    title: "Regional data placement concept",
    description:
      "Conceptual EU and US deployments each keep tickets, AI assistance, TxEventQ, and approval history locally. Support policies can be shared. This topology is not installed by the lab.",
    category: "Context",
  },
];
