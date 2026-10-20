// Chapters follow the README's manual workflow. Navigation never submits work.
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
    nodes: [
      "ui",
      "app",
      "data",
      "queue",
      "worker",
      "ai",
      "vector",
      "history",
      "cache",
      "telemetry",
    ],
    edges: [],
    practice: "Check your starting point",
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
    steps: [
      "Use the MFA sample below. Read or edit the title and description; leave the optional correlation ID blank.",
      "Click Publish ticket event, then View ticket in the receipt. This creates a real ticket and can call OCI.",
      "Watch the ticket move from RECEIVED to ENRICHED. Live refresh polls every five seconds; Refresh checks immediately.",
    ],
    mechanism:
      "Spring Boot commits support_ticket and the TxEventQ event together. The envelope carries IDs, timestamps, and trace context; the ticket text stays in the database.",
    evidence:
      "The publication receipt includes the ticket ID. Inspect the ticket below for workflow status and saved assistance. TRIAGED means processing ran without AI; FAILED means continue to the Recover chapter.",
    nodes: ["ui", "app", "data", "queue"],
    edges: ["submit", "write", "publish"],
    actions: [
      {
        label: "Open MFA sample",
        tab: "samples",
        preset: "mfa",
      },
      { label: "Inspect tickets", tab: "tickets", readPath: "primary" },
    ],
  },
  {
    id: "enrich",
    practice: "Inspect assistance or publish a comparison",
    title: "Follow AI enrichment",
    short: "Enrich",
    animation: {
      title: "AI enrichment and vector search",
      file: "/diagrams/04-ai-and-vector-search.svg",
      alt: "Animated flow from ticket text through OCI Generative AI and Oracle vector search to saved assistance and scored matches.",
    },
    summary:
      "A background consumer embeds the request, retrieves matches, and saves generated assistance.",
    steps: [
      "Select an ENRICHED ticket below. Read the saved summary, suggested resolution, model name, prompt version, generation time, policy matches, and related tickets.",
      "Choose Submit a comparison ticket below and publish the MFA sample again to build a comparison history. Three synthetic resolved reference tickets provide initial comparison data.",
      "Try Account access to distinguish a tenant mismatch from lost MFA, or Billing dispute to inspect a human-review recommendation. Outside the policy corpus demonstrates missing evidence. Choose Inspect saved assistance to compare the results.",
    ],
    mechanism:
      "OCI creates the embedding; Oracle performs exact cosine retrieval against tickets and policies. One chat call uses the ticket, retrieved policy bodies, and recorded resolutions from similar tickets to generate a summary and suggested next steps with source references. Unresolved descriptions and earlier AI suggestions are not proven fixes. Results, the processed event ID, and queue acknowledgement commit together.",
    evidence:
      "Look for ENRICHED, a summary and suggested resolution with source references, model/prompt metadata, indexed policies, and saved match scores. The application generates assistance; it does not change accounts or issue refunds.",
    nodes: ["queue", "worker", "ai", "vector", "data"],
    edges: ["consume", "generate", "retrieve", "save"],
    actions: [
      {
        label: "Inspect saved assistance",
        tab: "tickets",
        readPath: "primary",
      },
      {
        label: "Submit a comparison ticket",
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
    nodes: ["ui", "app", "history", "queue", "worker", "ai"],
    edges: ["submit", "review", "revise", "consume", "generate"],
    actions: [{ label: "Open Human Review", tab: "review" }],
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
    steps: [
      "Open the failure sample below and keep the [demo-fail-once] title prefix. Publish the ticket.",
      "Wait for FAILED, then choose Inspect Failed Events below. Inspect the error, attempt metadata, and replayable event ID.",
      "Click Replay event. The new event is linked to the original failure by its causation ID. With the default three attempts, replay fails transiently once before succeeding.",
      "Choose Inspect ticket below and confirm ENRICHED. The original failure leaves the active worklist and remains recorded as replayed.",
    ],
    mechanism:
      "A failed delivery stores failure metadata. Replay publishes a new event, so the normal consumer and retry path process it again. For an unexpected failure, fix its cause before replaying; OCI may be called again.",
    evidence:
      "Use the UI worklist for current replayable failures. A rolling Grafana failure count can remain positive after successful recovery because it still includes the earlier failure.",
    nodes: ["ui", "app", "data", "queue", "worker"],
    edges: ["submit", "write", "publish", "consume", "save"],
    actions: [
      {
        label: "Open failure sample",
        tab: "samples",
        preset: "failure",
      },
      { label: "Inspect Failed Events", tab: "failures" },
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
    steps: [
      "Choose Read list from primary below and note the ticket IDs and statuses.",
      "Switch Ticket list read path to True Cache · cache. Check Served by: true-cache confirms the cache served the list.",
      "If you see primary-fallback, the primary served the request because cache access failed. That does not prove a successful cache read.",
      "New tickets and statuses may lag while redo is applied. Switch back to Primary · fresh when checking the latest state. Detail and review screens always read primary.",
    ],
    mechanism:
      "True Cache is a read-only Oracle cache that follows committed changes through redo. It provides an alternate ticket-list read path; it is not a separate owner of workflow state.",
    evidence:
      "Compare the reported Served by value with the requested read path. A cache hit can be stale; primary-fallback is a different outcome. The snapshot below reports the last list read.",
    nodes: ["app", "data", "cache"],
    edges: ["redo", "cache-read"],
    actions: [
      { label: "Read list from primary", tab: "tickets", readPath: "primary" },
      { label: "Read list from True Cache", tab: "tickets", readPath: "cache" },
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
    nodes: ["app", "queue", "worker", "ai", "telemetry"],
    edges: ["submit", "consume", "app-telemetry", "worker-telemetry"],
    actions: [{ label: "Open Grafana", external: true }],
  },
];
