// Chapters follow the README's manual workflow. Navigation never submits work.
export const walkthrough = [
  {
    id: "ready",
    title: "Meet the lab",
    short: "Start here",
    requires: [],
    summary:
      "One request connects a Vue console, Spring Boot, Oracle AI Database, OCI Generative AI, True Cache, and Grafana.",
    steps: [
      "Start Compose, then Maven with events, ai, blockchain, demo-failures, and observability. Start the UI separately with npm.",
      "Check the configured profile badges above. At AI startup, three seeded support policies receive 1536-dimensional embeddings before the consumer subscribes to ticket_event.",
      "Use the chapter buttons to follow the flow. Play the diagram for a simulated tour, then use the action buttons to try the real lab.",
    ],
    mechanism:
      "TxEventQ lives inside Oracle AI Database. OKafka is its Kafka-style Java API; this lab has no separate Kafka broker. The event consumer runs inside the Spring Boot process.",
    evidence:
      "The inventory below shows current table counts, configured models, and policy indexing. Profile badges describe configuration, not external service health.",
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
    actions: [{ label: "Explore the overview", tab: "overview" }],
  },
  {
    id: "submit",
    title: "Submit a request",
    short: "Submit",
    requires: ["events"],
    summary: "Create a ticket and publish its work event in one transaction.",
    steps: [
      "Open the MFA sample below. Read or edit the title and description; leave the optional correlation ID blank.",
      "Click Publish ticket event, then View ticket in the receipt. This creates a real ticket and can call OCI.",
      "Watch the ticket move from RECEIVED to ENRICHED. Live refresh polls every five seconds; Refresh checks immediately.",
    ],
    mechanism:
      "Spring Boot commits support_ticket and the TxEventQ event together. The envelope carries IDs, timestamps, and trace context; the ticket text stays in the database.",
    evidence:
      "The publication receipt includes the ticket ID. In Tickets, inspect workflow status and the saved assistance. TRIAGED means processing ran without AI; FAILED means inspect Failed Events.",
    nodes: ["ui", "app", "data", "queue"],
    edges: ["submit", "write", "publish"],
    actions: [
      {
        label: "Open MFA sample",
        tab: "samples",
        mode: "ticket",
        preset: "mfa",
      },
      { label: "Inspect tickets", tab: "tickets", readPath: "primary" },
    ],
  },
  {
    id: "enrich",
    title: "Follow AI enrichment",
    short: "Enrich",
    requires: ["events", "ai"],
    summary:
      "A background consumer embeds the request, retrieves matches, and saves generated assistance.",
    steps: [
      "Open an ENRICHED ticket. Read the saved summary, model name, prompt version, generation time, policy matches, and related tickets.",
      "Submit the MFA sample a second time to build a comparison history. The first ticket may have no related-ticket matches.",
      "Try Account access or Billing dispute in Sample Data to compare policy suggestions for a different intent.",
    ],
    mechanism:
      "OCI creates the embedding; Oracle performs exact cosine retrieval against tickets and policies. The initial chat prompt uses the title and description. Retrieved matches are saved for the reviewer, not inserted into that prompt. Results, the processed event ID, and queue acknowledgement commit together.",
    evidence:
      "Look for ENRICHED, a nonempty summary, model/prompt metadata, indexed policies, and saved match scores. The application generates assistance; it does not change accounts or issue refunds.",
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
        mode: "ticket",
        preset: "mfa",
      },
    ],
  },
  {
    id: "review",
    title: "Revise, then approve",
    short: "Review",
    requires: ["events", "ai", "blockchain"],
    summary:
      "Human feedback returns through the event loop; each reviewed version is preserved.",
    steps: [
      "In Human Review, select an enriched ticket and enter a reviewer ID, such as demo-reviewer.",
      "Choose Request revision. Enter: “The affected account belongs to the test tenant. Include that context in the summary.” Then click Send feedback & regenerate.",
      "Wait for ENRICHED and a new generation timestamp. Compare the feedback with the revised summary, then choose Approve and click Approve summary.",
      "Human Review moves to the next pending ticket. Revisit the approved ticket in Tickets to inspect both review snapshots.",
    ],
    mechanism:
      "A rejection saves a blockchain review snapshot, appends feedback, and publishes regeneration in one transaction. Revision prompts include previous assistance and accumulated feedback. Approval preserves another snapshot and accepts the current summary without publishing a regeneration event.",
    evidence:
      "Review history preserves the earlier and revised summaries, reviewer IDs, decisions, and SHA-256 summary digests. Oracle V2 blockchain row chaining protects the history. Approval accepts assistance; it does not resolve or close the ticket.",
    nodes: ["ui", "app", "history", "queue", "worker", "ai"],
    edges: ["submit", "review", "revise", "consume", "generate"],
    actions: [
      { label: "Open Human Review", tab: "review" },
      { label: "Open preset feedback", tab: "samples", mode: "feedback" },
    ],
  },
  {
    id: "recover",
    title: "Recover a failed event",
    short: "Recover",
    requires: ["events", "ai", "demo-failures"],
    summary:
      "Deliberately fail an event, inspect the durable worklist, and replay the work.",
    steps: [
      "Open the failure sample below and keep the [demo-fail-once] title prefix. Publish the ticket.",
      "Wait for FAILED, then open Failed Events. Inspect the error, attempt metadata, and replayable event ID.",
      "Click Replay event. The new event is linked to the original failure by its causation ID. With the default three attempts, replay fails transiently once before succeeding.",
      "Return to Tickets and confirm ENRICHED. The original failure leaves the active worklist and remains recorded as replayed.",
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
        mode: "ticket",
        preset: "failure",
      },
      { label: "Inspect Failed Events", tab: "failures" },
    ],
  },
  {
    id: "cache",
    title: "Compare the read paths",
    short: "Cache",
    requires: ["events"],
    summary:
      "Read the ticket list through True Cache while keeping detail and review reads fresh.",
    steps: [
      "Open Tickets on Primary · fresh and note the ticket IDs and statuses.",
      "Switch Ticket list read path to True Cache · may lag. Check Served by: true-cache confirms the cache served the list.",
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
    title: "Connect the telemetry",
    short: "Observe",
    requires: ["observability"],
    summary:
      "Follow the same work through traces, event metrics, retries, and connection pool activity.",
    steps: [
      "Generate tickets, feedback, and a replay using the earlier chapters. Allow several five-second metric export intervals.",
      "Open Grafana → Oracle AI Database → Customer Support Workflow. Inspect event outcomes, retry attempts, processing time, and read paths.",
      "Open Oracle UCP Metrics to inspect pool usage and connection acquisition activity.",
      "In Explore, select Tempo and search service customer-support-lab-v2. Follow HTTP, publication, consumption, AI, feedback, replay, and JDBC spans.",
    ],
    mechanism:
      "Spring Boot exports OpenTelemetry traces and metrics to LGTM. Trace context travels with the event envelope so work can be correlated across the asynchronous handoff.",
    evidence:
      "The failed-events gauge estimates failures in a rolling window; it is not the current worklist. JSON console logs remain in the Maven terminal unless log forwarding is configured separately.",
    nodes: ["app", "queue", "worker", "ai", "telemetry"],
    edges: ["submit", "consume", "app-telemetry", "worker-telemetry"],
    actions: [{ label: "Open Grafana", external: true }],
  },
];
