<script setup>
import { computed } from "vue";
import StatusBadge from "./StatusBadge.vue";
import WorkflowFlow from "./WorkflowFlow.vue";
const props = defineProps({
  tickets: Array,
  snapshot: Object,
  failures: Array,
  ready: Array,
});
defineEmits(["navigate", "select"]);
const counts = computed(() =>
  Object.fromEntries(
    ["RECEIVED", "TRIAGED", "ENRICHED", "FAILED"].map((s) => [
      s,
      props.tickets.filter((t) => t.workflowStatus === s).length,
    ]),
  ),
);
const rowCount = (name) =>
  props.snapshot?.tables.find((t) => t.name === name)?.rows || 0;
</script>
<template>
  <div class="hero">
    <div>
      <div class="eyebrow">FROM REQUEST TO REVIEW</div>
      <h2>A clear view of every handoff.</h2>
      <p>
        Follow tickets through transactional events, AI enrichment, and human
        feedback — all in one local workspace.
      </p>
      <button class="button light" @click="$emit('navigate', 'review')">
        Open human review <span>↗</span>
      </button>
    </div>
    <div class="hero-mark" aria-hidden="true">
      <span>01 → 02</span><span>↖ 04 ← 03</span
      ><small>THE FEEDBACK LOOP</small>
    </div>
  </div>
  <div class="stats">
    <button class="stat panel" @click="$emit('navigate', 'tickets')">
      <span>Total tickets</span><strong>{{ tickets.length }}</strong
      ><small>{{ counts.RECEIVED }} awaiting processing</small>
    </button>
    <button class="stat panel" @click="$emit('navigate', 'review')">
      <span>Needs human review</span><strong>{{ ready.length }}</strong
      ><small>Enriched, not yet accepted</small>
    </button>
    <button class="stat panel" @click="$emit('navigate', 'failures')">
      <span>Failed worklist</span
      ><strong :class="{ danger: failures.length }">{{
        failures.length
      }}</strong
      ><small>Current replayable failures</small>
    </button>
    <button class="stat panel" @click="$emit('navigate', 'components')">
      <span>Review snapshots</span
      ><strong>{{ rowCount("ticket_approval_history") }}</strong
      ><small>Preserved in blockchain history</small>
    </button>
  </div>
  <section class="panel padded">
    <div class="section-heading">
      <div>
        <div class="eyebrow">HOW THE LAB WORKS</div>
        <h3>One event flow. A complete feedback loop.</h3>
      </div>
      <span class="subtle-tag">Oracle TxEventQ + OKafka</span>
    </div>
    <WorkflowFlow />
  </section>
  <div class="overview-bottom">
    <section class="panel padded">
      <div class="section-heading">
        <h3>Recent tickets</h3>
        <button class="text-button" @click="$emit('navigate', 'tickets')">
          View all →
        </button>
      </div>
      <p v-if="!tickets.length" class="empty compact">
        No tickets yet. Create your first request to start the workflow.
      </p>
      <button
        v-for="ticket in tickets.slice(0, 5)"
        :key="ticket.id"
        class="recent-row"
        @click="$emit('select', ticket.id)"
      >
        <span class="ticket-id">#{{ ticket.id }}</span
        ><strong>{{ ticket.title }}</strong
        ><StatusBadge :value="ticket.workflowStatus" />
      </button>
    </section>
    <section class="panel padded">
      <div class="section-heading">
        <h3>Workflow snapshot</h3>
        <span class="muted small">Current state</span>
      </div>
      <div v-for="(count, status) in counts" :key="status" class="state-row">
        <StatusBadge :value="status" />
        <div class="bar">
          <span
            :style="{
              width: `${tickets.length ? (count / tickets.length) * 100 : 0}%`,
            }"
          ></span>
        </div>
        <strong>{{ count }}</strong>
      </div>
      <p class="small muted">
        A ticket's workflow status and its review decision are separate.
        Approval does not resolve or close the ticket.
      </p>
    </section>
  </div>
</template>
