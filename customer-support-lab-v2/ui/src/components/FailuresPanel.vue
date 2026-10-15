<script setup>
import { ref } from "vue";
import { post, formatTime } from "../api";
import StatusBadge from "./StatusBadge.vue";
defineProps({ failures: Array });
const emit = defineEmits(["updated", "select", "replayed"]);
const pending = ref(null),
  error = ref(""),
  notice = ref("");
async function replay(event) {
  pending.value = event.eventId;
  error.value = "";
  notice.value = "";
  try {
    const result = await post(
      `/ticket-events/failures/${event.eventId}/replay`,
    );
    notice.value = `Replay requested for ticket #${event.ticketId}. New event: ${result.data.eventId}. Processing runs asynchronously.`;
    emit("updated");
    emit("replayed", result.data);
  } catch (e) {
    error.value = e.message;
  } finally {
    pending.value = null;
  }
}
</script>
<template>
  <p class="page-intro">
    Recorded failures are acknowledged so other work can continue. Fix the
    cause, then publish a replay linked to the original event.
  </p>
  <p v-if="error" class="alert error" role="alert">{{ error }}</p>
  <p v-if="notice" class="alert success" role="status">{{ notice }}</p>
  <div v-if="!failures.length" class="panel empty clear-state">
    <span class="clear-icon">✓</span>
    <h2>The worklist is clear.</h2>
    <p>
      No events are currently waiting for recovery. Historical failures remain
      stored after replay.
    </p>
  </div>
  <section
    v-for="event in failures"
    :key="event.eventId"
    class="panel padded failure-card"
  >
    <div class="section-heading">
      <div>
        <button class="text-button" @click="$emit('select', event.ticketId)">
          Ticket #{{ event.ticketId }} ↗
        </button>
        <h3>{{ event.failureType }}</h3>
      </div>
      <StatusBadge :value="event.status" />
    </div>
    <dl class="metadata">
      <dt>Event type</dt>
      <dd>{{ event.eventType }}</dd>
      <dt>Attempts</dt>
      <dd>{{ event.attemptCount }}</dd>
      <dt>Failed at</dt>
      <dd>{{ formatTime(event.failedAt) }}</dd>
      <dt>Event UUID</dt>
      <dd class="mono">{{ event.eventId }}</dd>
      <dt>Correlation UUID</dt>
      <dd class="mono">{{ event.correlationId }}</dd>
      <dt>Causation UUID</dt>
      <dd class="mono">{{ event.causationId || "Original submission" }}</dd>
    </dl>
    <div class="split">
      <p class="small muted">Replay may make additional OCI model calls.</p>
      <button
        class="button primary"
        :disabled="pending !== null || !event.replayable"
        @click="replay(event)"
      >
        {{ pending === event.eventId ? "Requesting…" : "Replay event →" }}
      </button>
    </div>
  </section>
</template>
