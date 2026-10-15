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
const emit = defineEmits(["updated", "select"]);
const ticket = ref(null),
  assistance = ref(null),
  history = ref([]),
  error = ref(""),
  loading = ref(false);
let generation = 0;
const has = (profile) => props.snapshot?.profiles.includes(profile);
async function load() {
  const version = ++generation;
  if (!props.ticketId) return;
  loading.value = true;
  try {
    const [t, a, h] = await Promise.all([
      request(`/tickets/${props.ticketId}?readPath=primary`),
      has("ai")
        ? request(`/tickets/${props.ticketId}/assistance`, { optional: true })
        : null,
      props.snapshot?.reviewEnabled
        ? request(`/tickets/${props.ticketId}/approvals`)
        : null,
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
async function saved() {
  await load();
  emit("updated");
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
        consumer commits the summary and ENRICHED status together.
      </div>
      <div v-if="ticket.workflowStatus === 'FAILED'" class="alert error">
        Processing failed. The previous assistance, if any, is retained. Inspect
        Failed Events to replay after correcting the cause.
      </div>
      <div v-if="ticket.reviewFeedback" class="feedback-note">
        <div class="eyebrow">ACCUMULATED HUMAN FEEDBACK</div>
        <p class="pre-wrap">{{ ticket.reviewFeedback }}</p>
      </div>
      <section class="assistance">
        <div class="section-heading">
          <h3>AI assistance</h3>
          <span class="muted small">Saved output</span>
        </div>
        <template v-if="assistance">
          <blockquote class="summary-text">{{ assistance.summary }}</blockquote>
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
              <h4>Suggested policies</h4>
              <p v-if="!assistance.policies.length" class="muted small">
                No policy matches above the threshold.
              </p>
              <div
                v-for="policy in assistance.policies"
                :key="policy.policyId"
                class="match"
              >
                <span
                  >{{ policy.title }}<small>{{ policy.policyId }}</small></span
                ><span class="score">{{ percentage(policy.score) }}</span>
              </div>
            </div>
            <div>
              <h4>Related tickets</h4>
              <p v-if="!assistance.similarTickets.length" class="muted small">
                No related tickets above the threshold.
              </p>
              <button
                v-for="related in assistance.similarTickets"
                :key="related.relatedTicketId"
                class="match match-link"
                @click="emit('select', related.relatedTicketId)"
              >
                <span>Ticket #{{ related.relatedTicketId }}</span
                ><span class="score">{{ percentage(related.score) }} ↗</span>
              </button>
            </div>
          </div>
          <p class="small muted">
            Scores are cosine similarity, not confidence. Matches are
            suggestions for a human agent.
          </p>
        </template>
        <p v-else class="empty compact">
          {{
            has("ai")
              ? "No saved assistance yet. It will appear after enrichment commits."
              : "Enable the ai profile for summaries, policy matches, and related tickets."
          }}
        </p>
      </section>
      <ReviewForm
        v-if="reviewMode"
        :key="ticket.id"
        :ticket="ticket"
        :assistance="assistance"
        :enabled="snapshot?.reviewEnabled && !error"
        @saved="saved"
      />
      <ApprovalHistory v-if="snapshot?.reviewEnabled" :history="history" />
    </template>
  </div>
</template>
