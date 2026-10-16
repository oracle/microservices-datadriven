<script setup>
import { computed, ref, watch, onUnmounted } from "vue";
import { post, request, formatTime } from "../api";
import { ticketSamples, feedbackSamples } from "../samples";
import ReviewForm from "./ReviewForm.vue";
import FailuresPanel from "./FailuresPanel.vue";
import StatusBadge from "./StatusBadge.vue";

const props = defineProps({
  launch: Object,
  snapshot: Object,
  tickets: Array,
  failures: Array,
  refreshedAt: Date,
});
const emit = defineEmits(["updated", "select"]);
const mode = ref("ticket"),
  selected = ref("mfa");
const title = ref(ticketSamples[0].title),
  description = ref(ticketSamples[0].description);
const correlationId = ref("");
const pending = ref(false),
  error = ref(""),
  receipt = ref(null),
  recent = ref([]);
const reviewPending = ref(false);
const feedbackPreset = ref("tenant"),
  ticketId = ref("");
const ticket = ref(null),
  assistance = ref(null),
  feedbackError = ref(""),
  feedbackLoading = ref(false);
let loadVersion = 0;
const has = (profile) => props.snapshot?.profiles.includes(profile);
const sample = computed(() =>
  ticketSamples.find((s) => s.id === selected.value),
);
const payload = computed(() => ({
  title: title.value.trim(),
  description: description.value.trim(),
}));
const missingFailureProfile = computed(
  () =>
    payload.value.title.startsWith("[demo-fail-once]") && !has("demo-failures"),
);
const feedbackText = computed(
  () =>
    feedbackSamples.find((s) => s.id === feedbackPreset.value)?.reason || "",
);
const selectableTickets = computed(() =>
  props.tickets.filter(
    (t) => t.workflowStatus === "ENRICHED" || t.id === Number(ticketId.value),
  ),
);
const canPublish = computed(
  () =>
    has("events") &&
    !missingFailureProfile.value &&
    payload.value.title &&
    payload.value.description &&
    !pending.value,
);

function choose(id) {
  const preset = ticketSamples.find((s) => s.id === id);
  selected.value = id;
  title.value = preset?.title || "";
  description.value = preset?.description || "";
  error.value = "";
}
function remember(entry) {
  receipt.value = { ...entry, at: new Date().toISOString() };
  recent.value = [receipt.value, ...recent.value].slice(0, 8);
}
async function publish() {
  if (!canPublish.value) return;
  const uuid = correlationId.value.trim();
  if (
    uuid &&
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      uuid,
    )
  ) {
    error.value =
      "Use a canonical UUID for the correlation ID, or leave it blank.";
    return;
  }
  pending.value = true;
  error.value = "";
  receipt.value = null;
  try {
    const { data } = await post(
      "/tickets",
      payload.value,
      uuid ? { headers: { "X-Correlation-ID": uuid } } : {},
    );
    ticketId.value = String(data.id);
    remember({
      kind: "TICKET_SUBMITTED",
      ticketId: data.id,
      message: `Ticket #${data.id} and its event committed. Processing runs asynchronously.`,
    });
    emit("updated");
  } catch (e) {
    error.value = `${e.message} If the response was lost, the ticket may have committed. Check Tickets before submitting again.`;
  } finally {
    pending.value = false;
  }
}
async function loadFeedback() {
  const version = ++loadVersion;
  if (
    mode.value !== "feedback" ||
    !ticketId.value ||
    !props.snapshot.reviewEnabled
  )
    return;
  feedbackLoading.value = true;
  const id = Number(ticketId.value);
  try {
    const [t, a] = await Promise.all([
      request(`/tickets/${id}?readPath=primary`),
      request(`/tickets/${id}/assistance`, { optional: true }),
    ]);
    if (version !== loadVersion) return;
    ticket.value = t.data;
    assistance.value = a?.data || null;
    feedbackError.value = "";
  } catch (e) {
    if (version === loadVersion) feedbackError.value = e.message;
  } finally {
    if (version === loadVersion) feedbackLoading.value = false;
  }
}
watch(ticketId, () => {
  ticket.value = null;
  assistance.value = null;
  feedbackError.value = "";
  loadFeedback();
});
watch(mode, () => {
  error.value = "";
  if (mode.value === "feedback") {
    if (!ticketId.value && selectableTickets.value.length)
      ticketId.value = String(selectableTickets.value[0].id);
    else loadFeedback();
  } else {
    ++loadVersion;
    feedbackLoading.value = false;
  }
});
watch(
  () => props.refreshedAt,
  () => {
    if (
      mode.value === "feedback" &&
      !ticketId.value &&
      selectableTickets.value.length
    )
      ticketId.value = String(selectableTickets.value[0].id);
    else loadFeedback();
  },
);
async function reviewed(review) {
  remember({
    kind:
      review.decision === "REJECTED"
        ? "TICKET_FEEDBACK_SUBMITTED"
        : "APPROVED · no event",
    ticketId: review.ticketId,
    actionId: review.actionId,
    message:
      review.decision === "REJECTED"
        ? `Feedback saved for ticket #${review.ticketId}; regeneration requested.`
        : `Ticket #${review.ticketId} summary approved. Approval publishes no event.`,
  });
  emit("updated");
  await loadFeedback();
}
function replayed(event) {
  remember({
    kind: `Replay · ${event.eventType}`,
    ticketId: event.ticketId,
    eventId: event.eventId,
    message: `Replay published for ticket #${event.ticketId}; new event ${event.eventId}.`,
  });
}
watch(
  () => props.launch,
  (launch) => {
    if (!launch) return;
    mode.value = launch.mode || "ticket";
    if (launch.preset) choose(launch.preset);
  },
  { immediate: true },
);
onUnmounted(() => ++loadVersion);
</script>
<template>
  <div class="sample-modes" role="group" aria-label="Sample event type">
    <button
      class="button"
      :class="{ primary: mode === 'ticket' }"
      :aria-pressed="mode === 'ticket'"
      :disabled="pending || reviewPending"
      @click="mode = 'ticket'"
    >
      01 · Submit ticket
    </button>
    <button
      class="button"
      :class="{ primary: mode === 'feedback' }"
      :aria-pressed="mode === 'feedback'"
      :disabled="pending || reviewPending"
      @click="mode = 'feedback'"
    >
      02 · Submit feedback
    </button>
    <button
      class="button"
      :class="{ primary: mode === 'replay' }"
      :aria-pressed="mode === 'replay'"
      :disabled="pending || reviewPending"
      @click="mode = 'replay'"
    >
      03 · Replay event
      <span v-if="failures.length">({{ failures.length }})</span>
    </button>
  </div>
  <div v-if="receipt" class="alert success sample-receipt" role="status">
    <div>
      <strong>{{ receipt.kind }}</strong>
      <p>{{ receipt.message }}</p>
    </div>
    <button class="text-button" @click="emit('select', receipt.ticketId)">
      View ticket #{{ receipt.ticketId }} ↗
    </button>
  </div>
  <template v-if="mode === 'ticket'">
    <p class="page-intro">
      Choose a scenario, edit its data, and publish. Each submission creates a
      new ticket and a TICKET_SUBMITTED event in one transaction.
    </p>
    <div class="sample-workspace">
      <section class="sample-presets" aria-label="Ticket presets">
        <button
          v-for="preset in ticketSamples"
          :key="preset.id"
          class="panel sample-preset"
          :class="{ selected: selected === preset.id }"
          :aria-pressed="selected === preset.id"
          :disabled="pending"
          @click="choose(preset.id)"
        >
          <span class="eyebrow">{{ preset.category }}</span
          ><strong>{{ preset.name }}</strong>
          <p>{{ preset.outcome }}</p>
          <span v-if="preset.requires" class="subtle-tag"
            >Requires {{ preset.requires }}</span
          >
        </button>
        <button
          class="panel sample-preset"
          :class="{ selected: selected === 'custom' }"
          :aria-pressed="selected === 'custom'"
          :disabled="pending"
          @click="choose('custom')"
        >
          <span class="eyebrow">YOUR OWN DATA</span
          ><strong>Custom ticket</strong>
          <p>
            Start with a blank request and write your own title and description.
          </p>
        </button>
      </section>
      <section class="panel padded sample-composer">
        <div class="section-heading">
          <div>
            <div class="eyebrow">TICKET_SUBMITTED</div>
            <h3>{{ sample?.name || "Publish your own ticket" }}</h3>
          </div>
          <span class="subtle-tag">POST /tickets</span>
        </div>
        <form @submit.prevent="publish">
          <fieldset :disabled="pending || !has('events')">
            <label
              >Ticket title<input
                v-model="title"
                required
                maxlength="255"
                placeholder="What does the customer need help with?"
            /></label>
            <label
              >Ticket description<textarea
                v-model="description"
                required
                maxlength="2000"
                rows="6"
                placeholder="Describe the issue, context, and requested help…"
              />
            </label>
            <label
              >Correlation ID (optional)<input
                v-model="correlationId"
                maxlength="36"
                placeholder="Leave blank to generate one automatically"
            /></label>
            <p class="small muted">
              A correlation ID groups work; it does not deduplicate submissions.
            </p>
            <div v-if="missingFailureProfile" class="alert info">
              Enable demo-failures to run a title beginning with
              [demo-fail-once]. Choose another preset for a regular submission.
            </div>
            <div v-if="error" class="alert error" role="alert">{{ error }}</div>
            <div class="split">
              <span class="small muted"
                >{{
                  has("ai")
                    ? "Expected result: ENRICHED"
                    : "Expected result: TRIAGED (ai disabled)"
                }}{{
                  payload.title.startsWith("[demo-fail-once]")
                    ? " after replay"
                    : ""
                }}</span
              ><button class="button primary" :disabled="!canPublish">
                {{ pending ? "Publishing…" : "Publish ticket event →" }}
              </button>
            </div>
          </fieldset>
        </form>
        <details class="sample-request" open>
          <summary>Request preview</summary>
          <pre>{{ JSON.stringify(payload, null, 2) }}</pre>
          <p class="small muted">
            The server creates the OSON event envelope, UUID, timestamp, and
            trace context. Ticket text is stored in Oracle; the event carries
            IDs.
          </p>
        </details>
        <p v-if="sample" class="small muted sample-source">
          Based on {{ sample.source }}. Every preset can be edited before
          publishing.
        </p>
      </section>
    </div>
  </template>
  <template v-else-if="mode === 'feedback'">
    <p class="page-intro">
      A rejected review saves feedback on an existing enriched ticket and
      publishes TICKET_FEEDBACK_SUBMITTED. The same consumer regenerates its
      summary and matches.
    </p>
    <div v-if="!snapshot.reviewEnabled" class="alert info">
      Enable events, ai, and blockchain to submit feedback. You can create
      tickets with the first tab.
    </div>
    <section v-else class="panel padded sample-feedback">
      <div class="sample-feedback-selectors">
        <label
          >Ticket to revise<select v-model="ticketId" :disabled="reviewPending">
            <option disabled value="">Choose an enriched ticket</option>
            <option
              v-for="item in selectableTickets"
              :key="item.id"
              :value="String(item.id)"
            >
              #{{ item.id }} · {{ item.title }} · {{ item.workflowStatus }}
            </option>
          </select></label
        ><label
          >Feedback preset<select
            v-model="feedbackPreset"
            :disabled="reviewPending"
          >
            <option
              v-for="preset in feedbackSamples"
              :key="preset.id"
              :value="preset.id"
            >
              {{ preset.name }}
            </option>
          </select></label
        >
      </div>
      <p v-if="!selectableTickets.length" class="empty compact">
        No enriched tickets yet. Publish a ticket with ai enabled, then return
        here when processing completes.
      </p>
      <p v-if="feedbackError" class="alert error" role="alert">
        {{ feedbackError }}
        <button class="text-button" @click="loadFeedback">Retry</button>
      </p>
      <p v-if="feedbackLoading && !ticket" class="muted">
        Loading the current ticket and summary from primary…
      </p>
      <template v-if="ticket"
        ><div class="section-heading">
          <h3>Current saved summary · #{{ ticket.id }}</h3>
          <StatusBadge :value="ticket.workflowStatus" />
        </div>
        <blockquote v-if="assistance" class="summary-text">
          {{ assistance.summary }}
        </blockquote>
        <p v-else class="muted">No saved summary yet.</p>
        <ReviewForm
          :key="ticket.id"
          :ticket="ticket"
          :assistance="assistance"
          :enabled="snapshot.reviewEnabled && !feedbackError"
          :initial-feedback="feedbackText"
          @saved="reviewed"
          @busy="(value) => (reviewPending = value)"
      /></template>
    </section>
  </template>
  <FailuresPanel
    v-else
    :failures="failures"
    @updated="emit('updated')"
    @select="(id) => emit('select', id)"
    @replayed="replayed"
  />
  <section v-if="recent.length" class="panel padded sample-recent">
    <div class="section-heading">
      <h3>Requests from this screen</h3>
      <span class="muted small">Most recent {{ recent.length }}</span>
    </div>
    <div
      v-for="(entry, index) in recent"
      :key="index"
      class="sample-recent-row"
    >
      <div>
        <strong>{{ entry.kind }}</strong>
        <p class="small muted">
          {{ formatTime(entry.at)
          }}<span v-if="entry.actionId"> · Action {{ entry.actionId }}</span
          ><span v-if="entry.eventId"> · Event {{ entry.eventId }}</span>
        </p>
      </div>
      <button class="text-button" @click="emit('select', entry.ticketId)">
        Ticket #{{ entry.ticketId }} ↗
      </button>
    </div>
  </section>
</template>
