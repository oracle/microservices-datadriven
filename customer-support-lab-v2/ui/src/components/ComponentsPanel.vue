<script setup>
import StatusBadge from "./StatusBadge.vue";
defineProps({ snapshot: Object, actualPath: String, grafanaUrl: String });
const ticketEvents = ["TICKET_SUBMITTED", "TICKET_FEEDBACK_SUBMITTED"];
const tables = [
  [
    "support_ticket",
    "Source of truth",
    "Request text, accumulated human feedback, workflow status, recorded resolution, and the ticket embedding.",
  ],
  [
    "ticket_assistance",
    "Current AI output",
    "The latest summary and suggested resolution with model, prompt version, and generation time.",
  ],
  [
    "related_ticket",
    "Ticket retrieval",
    "Scored links from one ticket to other tickets with embeddings.",
  ],
  [
    "support_policy",
    "Policy corpus",
    "Three seeded support policies and their startup-created embeddings.",
  ],
  [
    "ticket_policy_match",
    "Policy retrieval",
    "Scored policy suggestions replaced with each enrichment.",
  ],
  [
    "ticket_event_processed",
    "Durable deduplication",
    "Successfully processed event UUIDs and commit timestamps.",
  ],
  [
    "failed_ticket_event",
    "Recovery worklist",
    "Failure metadata retained as FAILED or REPLAYED.",
  ],
  [
    "ticket_approval_history",
    "Blockchain history",
    "Append-only review snapshots, complete assistance digests, reviewer IDs, and decisions.",
  ],
];
</script>
<template>
  <p class="page-intro">
    Explore the services, models, and data behind the workflow. All features run by default. The inventory does not establish external service health.
  </p>
  <div class="component-grid">
    <section class="panel padded">
      <div class="component-icon">DB</div>
      <div class="section-heading">
        <h3>Oracle AI Database</h3>
        <span class="subtle-tag">Primary</span>
      </div>
      <p>
        Ticket state, vector retrieval, event transactions, and blockchain
        history share one database.
      </p>
      <dl class="metadata">
        <dt>Tickets</dt>
        <dd>Fresh detail reads always use primary.</dd>
        <dt>Vector search</dt>
        <dd>Exact cosine · minimum 0.2 · 1536 dimensions</dd>
      </dl>
    </section>
    <section class="panel padded">
      <div class="component-icon">↔</div>
      <div class="section-heading">
        <h3>TxEventQ + OKafka</h3>
        <StatusBadge value="ENABLED" />
      </div>
      <p>
        Oracle's transactional event queue, accessed through the OKafka API.
        Publication commits with ticket writes; acknowledgement commits with
        processing results.
      </p>
      <dl class="metadata">
        <dt>Topics</dt>
        <dd class="mono">{{ snapshot.topic }}</dd>
        <dt>Event types</dt>
        <dd>
          <div v-for="event in ticketEvents" :key="event" class="mono">{{ event }}</div>
        </dd>
        <dt>Envelopes</dt>
        <dd>
          IDs, timestamps, and trace context; ticket text stays in the database.
        </dd>
      </dl>
    </section>
    <section class="panel padded">
      <div class="component-icon">AI</div>
      <div class="section-heading">
        <h3>OCI Generative AI</h3>
        <StatusBadge value="ENABLED" />
      </div>
      <dl class="metadata">
        <dt>Summary model</dt>
        <dd>{{ snapshot.chatModel }}</dd>
        <dt>Embedding model</dt>
        <dd>{{ snapshot.embeddingModel }}</dd>
      </dl>
      <p>
        Embeds the request, retrieves matches, and generates a summary and suggested resolution from policy bodies and recorded ticket outcomes.
        Revisions include previous assistance and accumulated feedback.
        Retrieved matches are saved for human review.
      </p>
    </section>
    <section class="panel padded">
      <div class="component-icon">TC</div>
      <div class="section-heading">
        <h3>True Cache</h3>
        <span class="subtle-tag">Read path</span>
      </div>
      <p>
        Read-only Oracle cache follows committed changes through redo. Ticket
        lists can request cache reads; detail and review views use primary for
        freshness.
      </p>
      <dl class="metadata">
        <dt>Last list read</dt>
        <dd>{{ actualPath || "No read yet" }}</dd>
        <dt>Fallback</dt>
        <dd>The API reports primary-fallback if cache access fails.</dd>
      </dl>
    </section>
    <section class="panel padded">
      <div class="component-icon">✓</div>
      <div class="section-heading">
        <h3>Human review + blockchain</h3>
        <StatusBadge value="ENABLED" />
      </div>
      <p>
        Approval accepts the saved assistance. Rejection stores feedback and
        publishes a regeneration event in the review transaction.
      </p>
      <dl class="metadata">
        <dt>Integrity</dt>
        <dd>
          Oracle V2 SHA2-512 row chaining; separate SHA-256 assistance digest.
        </dd>
        <dt>Retention</dt>
        <dd>
          Rows: 16 days. Table drop: 0 days idle, for deliberate lab cleanup.
        </dd>
      </dl>
    </section>
    <section class="panel padded">
      <div class="component-icon">⌁</div>
      <div class="section-heading">
        <h3>Observability</h3>
        <StatusBadge value="ENABLED" />
      </div>
      <p>
        OpenTelemetry traces and metrics flow to the local LGTM stack. Inspect
        HTTP, consumer, AI, JDBC spans, event outcomes, retries, and UCP
        activity.
      </p>
      <a class="text-button" :href="grafanaUrl" target="_blank" rel="noopener"
        >Open Grafana ↗</a
      >
      <p class="small muted">
        Application logs are exported to Loki over OTLP and also remain available
        as JSON in the Maven terminal.
      </p>
    </section>
  </div>
  <section class="panel padded schema-panel">
    <div class="section-heading">
      <div>
        <div class="eyebrow">THE APPLICATION SCHEMA</div>
        <h3>Tables and TxEventQ topics.</h3>
      </div>
      <span class="subtle-tag">Snapshot row counts</span>
    </div>
    <p class="muted">
      Eight tables store application state and outcomes. The configured topic
      carries submission and feedback events; TxEventQ manages its queue storage.
    </p>
    <div class="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Table</th>
            <th>Role</th>
            <th>Rows</th>
            <th>What it stores</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="[name, role, description] in tables" :key="name">
            <td class="mono">{{ name }}</td>
            <td>{{ role }}</td>
            <td class="count-cell">
              {{ snapshot.tables.find((t) => t.name === name)?.rows ?? "—" }}
            </td>
            <td>{{ description }}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="schema-topics">
      <h4>TxEventQ topics</h4>
      <p class="mono">{{ snapshot.topic }}</p>
      <p>
        Ticket submission and feedback share this topic. The background consumer
        processes both event types. Replay publishes a new event to the same
        topic, preserving the original event type.
      </p>
      <details>
        <summary>Event types &amp; transaction boundaries</summary>
        <dl class="metadata">
          <dt class="mono">{{ ticketEvents[0] }}</dt>
          <dd>Ticket creation and event publication commit together.</dd>
          <dt class="mono">{{ ticketEvents[1] }}</dt>
          <dd>Review snapshot, feedback, and regeneration publication commit together.</dd>
        </dl>
        <p class="small muted">
          Topic names reflect the application configuration. Failure history
          is stored in failed_ticket_event. The table row counts above describe
          stored application data; topic queue depth is a separate metric.
        </p>
      </details>
    </div>
  </section>
  <section class="panel padded">
    <div class="section-heading">
      <h3>Policy corpus</h3>
      <span class="muted small">Embeddings created at AI startup</span>
    </div>
    <div class="policy-grid">
      <article v-for="policy in snapshot.policies" :key="policy.id">
        <div class="split">
          <span class="eyebrow">{{ policy.id }}</span
          ><StatusBadge :value="policy.indexed ? 'INDEXED' : 'PENDING'" />
        </div>
        <h4>{{ policy.title }}</h4>
        <p>{{ policy.body }}</p>
      </article>
    </div>
  </section>
</template>
