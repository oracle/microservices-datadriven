<script setup>
import { ref, watch, onUnmounted } from "vue";
import { request, formatTime, percentage } from "../api";
import StatusBadge from "./StatusBadge.vue";
import ReviewForm from "./ReviewForm.vue";
import ApprovalHistory from "./ApprovalHistory.vue";
const props = defineProps({
  ticketId: Number,
  snapshot: Object,
  refreshedAt: Date,
  reviewMode: Boolean,
});
const emit = defineEmits(["updated", "select", "reviewed"]);
const ticket = ref(null),
  assistance = ref(null),
  history = ref([]),
  error = ref(""),
  loading = ref(false);
let generation = 0;
async function load() {
  const version = ++generation;
  if (!props.ticketId) return;
  loading.value = true;
  try {
    const [t, a, h] = await Promise.all([
      request(`/tickets/${props.ticketId}?readPath=primary`),
      request(`/tickets/${props.ticketId}/assistance`, { optional: true }),
      request(`/tickets/${props.ticketId}/approvals`),
    ]);
    if (version !== generation) return;
    ticket.value = t.data;
    assistance.value = a?.data || null;
    history.value = h?.data || [];
    error.value = "";
  } catch (e) {
    if (version === generation) error.value = e.message;
  } finally {
    if (version === generation) loading.value = false;
  }
}
watch(
  () => props.ticketId,
  () => {
    ticket.value = null;
    assistance.value = null;
    history.value = [];
    error.value = "";
    load();
  },
  { immediate: true },
);
watch(() => props.refreshedAt, load);
onUnmounted(() => generation++);
async function saved(review) {
  emit("updated");
  emit("reviewed", { ...review, generatedAt: assistance.value?.generatedAt });
  if (review.decision !== "APPROVED") await load();
}
</script>
<template>
  <div class="ticket-detail panel">
    <p v-if="error" role="alert" class="alert error">
      {{ error }} <button class="text-button" @click="load">Retry</button>
    </p>
    <div v-if="!ticket" class="empty">
      {{
        loading ? "Loading ticket…" : "Select a ticket to explore its workflow."
      }}
    </div>
    <template v-else>
      <div class="split">
        <span class="eyebrow">TICKET #{{ ticket.id }} · PRIMARY READ</span
        ><StatusBadge :value="ticket.workflowStatus" />
      </div>
      <h2>{{ ticket.title }}</h2>
      <p class="ticket-description">{{ ticket.description }}</p>
      <div v-if="ticket.workflowStatus === 'RECEIVED'" class="alert info">
        Processing is pending. This view refreshes with the workspace; the
        consumer commits the assistance and ENRICHED status together.
      </div>
      <div v-if="ticket.workflowStatus === 'FAILED'" class="alert error">
        Processing failed. The previous assistance, if any, is retained. Inspect
        Failed Events to replay after correcting the cause.
      </div>
      <div v-if="ticket.reviewFeedback" class="feedback-note">
        <div class="eyebrow">ACCUMULATED HUMAN FEEDBACK</div>
        <p class="pre-wrap">{{ ticket.reviewFeedback }}</p>
      </div>
      <div v-if="ticket.resolution" class="feedback-note">
        <div class="eyebrow">RECORDED RESOLUTION</div>
        <p class="pre-wrap">{{ ticket.resolution }}</p>
      </div>
      <section class="assistance">
        <div class="section-heading">
          <h3>AI assistance</h3>
          <span class="muted small">Saved output</span>
        </div>
        <template v-if="assistance">
          <blockquote class="summary-text">{{ assistance.summary }}</blockquote>
          <div v-if="assistance.suggestedResolution">
            <h4>Suggested resolution</h4>
            <p class="pre-wrap">{{ assistance.suggestedResolution }}</p>
            <p class="small muted">Proposed steps for human review; no customer action has been executed.</p>
          </div>
          <details :key="ticket.id" class="disclosure">
            <summary>Sources &amp; generation details</summary>
            <dl class="metadata">
              <dt>Generated</dt>
              <dd>{{ formatTime(assistance.generatedAt) }}</dd>
              <dt>Model</dt>
              <dd>{{ assistance.summaryModel }}</dd>
              <dt>Prompt</dt>
              <dd>{{ assistance.promptVersion }}</dd>
            </dl>
            <div class="matches">
              <div>
                <h4>Retrieved policies</h4>
                <p v-if="!assistance.policies.length" class="muted small">
                  No policy matches above the threshold.
                </p>
                <div
                  v-for="policy in assistance.policies"
                  :key="policy.policyId"
                >
                  <div class="match">
                    <span>{{ policy.title }}<small>{{ policy.policyId }}</small></span>
                    <span class="score">{{ percentage(policy.score) }}</span>
                  </div>
                  <details v-if="policy.body">
                    <summary>Read policy</summary>
                    <p class="pre-wrap small">{{ policy.body }}</p>
                  </details>
                </div>
              </div>
              <div>
                <h4>Related tickets</h4>
                <p v-if="!assistance.similarTickets.length" class="muted small">
                  No related tickets above the threshold.
                </p>
                <div
                  v-for="related in assistance.similarTickets"
                  :key="related.relatedTicketId"
                >
                  <button class="match match-link" @click="emit('select', related.relatedTicketId)">
                    <span>Ticket #{{ related.relatedTicketId }}<small>{{ related.title }}</small></span>
                    <span class="score">{{ percentage(related.score) }} ↗</span>
                  </button>
                  <details v-if="related.resolution">
                    <summary>Recorded resolution</summary>
                    <p class="pre-wrap small">{{ related.resolution }}</p>
                  </details>
                </div>
              </div>
            </div>
            <p class="small muted">
              Scores are cosine similarity, not confidence. Matches are
              retrieved context for a human agent. Only tickets with a recorded
              resolution are used as resolution examples; earlier AI suggestions are not proven fixes.
            </p>
          </details>
        </template>
        <p v-else class="empty compact">
          {{ ticket.resolution ? "Historical reference case; its recorded resolution can support similar tickets."
            : "No saved assistance yet. It will appear after enrichment commits." }}
        </p>
      </section>
      <ReviewForm
        v-if="reviewMode"
        :key="ticket.id"
        :ticket="ticket"
        :assistance="assistance"
        :enabled="!error"
        @saved="saved"
      />
      <ApprovalHistory :history="history" />
    </template>
  </div>
</template>
