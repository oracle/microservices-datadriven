<script setup>
import { computed, ref, watch } from "vue";
import { post, formatTime } from "../api";
import { ticketSamples } from "../samples";

const props = defineProps({
  launch: Object,
  snapshot: Object,
});
const emit = defineEmits(["updated", "select", "created"]);
const selected = ref("mfa");
const title = ref(ticketSamples[0].title),
  description = ref(ticketSamples[0].description);
const correlationId = ref("");
const pending = ref(false),
  error = ref(""),
  receipt = ref(null),
  recent = ref([]);
const sample = computed(() =>
  ticketSamples.find((s) => s.id === selected.value),
);
const payload = computed(() => ({
  title: title.value.trim(),
  description: description.value.trim(),
}));
const canPublish = computed(
  () =>
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
    remember({
      kind: "TICKET_SUBMITTED",
      ticketId: data.id,
      message: `Ticket #${data.id} and its event committed. Processing runs asynchronously.`,
    });
    emit("created", data.id);
    emit("updated");
  } catch (e) {
    error.value = `${e.message} If the response was lost, the ticket may have committed. Check Tickets before submitting again.`;
  } finally {
    pending.value = false;
  }
}
watch(
  () => props.launch,
  (launch) => {
    if (!launch) return;
    if (launch.preset) choose(launch.preset);
  },
  { immediate: true },
);
</script>
<template>
  <div v-if="receipt" class="alert success sample-receipt" role="status">
    <div>
      <strong>{{ receipt.kind }}</strong>
      <p>{{ receipt.message }}</p>
    </div>
    <button class="text-button" @click="emit('select', receipt.ticketId)">
      View ticket #{{ receipt.ticketId }} ↗
    </button>
  </div>
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
        <fieldset :disabled="pending">
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
          <div v-if="error" class="alert error" role="alert">{{ error }}</div>
          <div class="split">
            <span class="small muted"
              >Expected result: ENRICHED{{
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
          {{ formatTime(entry.at) }}
        </p>
      </div>
      <button class="text-button" @click="emit('select', entry.ticketId)">
        Ticket #{{ entry.ticketId }} ↗
      </button>
    </div>
  </section>
</template>
