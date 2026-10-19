<script setup>
import { computed, ref, watch, nextTick } from "vue";
import { walkthrough } from "../walkthrough";
import { needsReview } from "../api";
import SampleDataPanel from "./SampleDataPanel.vue";
import TicketWorkspace from "./TicketWorkspace.vue";
import FailuresPanel from "./FailuresPanel.vue";
import TicketDetail from "./TicketDetail.vue";
import ReadPathControl from "./ReadPathControl.vue";
import ComponentsPanel from "./ComponentsPanel.vue";
const props = defineProps({
  snapshot: Object,
  tickets: Array,
  failures: Array,
  actualPath: String,
  grafanaUrl: String,
  step: Number,
  readPath: String,
  refreshedAt: Date,
});
const emit = defineEmits(["updated", "update:step", "update:readPath"]);
const chapter = computed(() => walkthrough[props.step]);
const activeView = ref("");
const selectedId = ref(null);
const chapterNav = ref(null);
const presets = { mfa: { preset: "mfa" }, failure: { preset: "failure" } };
const sampleLaunch = computed(() =>
  chapter.value.id === "recover" ? presets.failure : presets.mfa,
);
const reviewId = computed(() =>
  props.tickets.some(
    (ticket) =>
      ticket.id === selectedId.value && needsReview(ticket, props.snapshot),
  )
    ? selectedId.value
    : null,
);
watch(
  () => props.step,
  () => {
    activeView.value = chapter.value.actions[0]?.tab || chapter.value.id;
    if (chapter.value.id !== "cache") emit("update:readPath", "primary");
  },
  { immediate: true },
);
watch(
  () => props.step,
  async () => {
    await nextTick();
    chapterNav.value?.scrollIntoView({
      block: "start",
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "auto"
        : "smooth",
    });
  },
);
function act(action) {
  activeView.value = action.tab || "observe";
  if (action.readPath) emit("update:readPath", action.readPath);
}
function inspect(id) {
  selectedId.value = id;
  activeView.value = "detail";
}
const count = (name) =>
  props.snapshot.tables.find((table) => table.name === name)?.rows ?? 0;
</script>
<template>
  <div class="walkthrough-intro">
    <div>
      <div class="eyebrow">FOLLOW A REQUEST THROUGH THE LAB</div>
      <h2>One workflow. Every component.</h2>
      <p>
        Seven chapters connect the architecture to the real console. Choose a
        chapter, try its actions below, and inspect the results without leaving
        the walkthrough. Move to the next chapter when you’re ready.
      </p>
    </div>
    <a
      class="text-button"
      href="https://github.com/oracle/microservices-datadriven/blob/main/customer-support-lab-v2/README.md"
      target="_blank"
      rel="noopener"
      >Read the setup guide ↗</a
    >
  </div>
  <nav
    ref="chapterNav"
    class="walkthrough-chapters"
    aria-label="Walkthrough chapters"
  >
    <button
      v-for="(item, index) in walkthrough"
      :key="item.id"
      :aria-current="step === index ? 'step' : undefined"
      :class="{ selected: step === index }"
      @click="emit('update:step', index)"
    >
      <span>{{ String(index + 1).padStart(2, "0") }}</span
      >{{ item.short }}
    </button>
  </nav>
  <div class="walkthrough-layout">
    <section
      class="panel padded walkthrough-chapter"
      aria-labelledby="chapter-title"
    >
      <div class="eyebrow">
        CHAPTER {{ step + 1 }} OF {{ walkthrough.length }}
      </div>
      <h2 id="chapter-title">{{ chapter.title }}</h2>
      <p class="walkthrough-summary">{{ chapter.summary }}</p>
      <p v-if="chapter.id === 'ready'">
        <a
          class="text-button"
          href="/diagrams/14-complete-event-loop.svg"
          target="_blank"
          rel="noopener"
          >Watch the complete event-loop animation ↗</a
        >
      </p>
      <ol>
        <li v-for="instruction in chapter.steps" :key="instruction">
          {{ instruction }}
        </li>
      </ol>
      <div class="walkthrough-explanation">
        <h3>What connects the components</h3>
        <p>{{ chapter.mechanism }}</p>
        <h3>What to look for</h3>
        <p>{{ chapter.evidence }}</p>
      </div>
    </section>
  </div>
  <section class="walkthrough-practice" aria-labelledby="practice-title">
    <div class="section-heading">
      <div>
        <div class="eyebrow">TRY IT HERE</div>
        <h2 id="practice-title">{{ chapter.practice }}</h2>
      </div>
      <span v-if="selectedId" class="subtle-tag"
        >Following ticket #{{ selectedId }}</span
      >
    </div>
    <p v-if="chapter.id === 'ready'" class="small muted">
      Check the live counts below and expand the component reference for models,
      table counts, and policies. Then continue to Submit to create your first
      ticket.
    </p>
    <p v-else class="small muted">
      Results refresh with the console. Submit, review, and replay when you’re
      ready; these actions write lab data and may call OCI.
    </p>
    <div
      v-if="chapter.actions.length"
      class="walkthrough-actions"
      role="group"
      aria-label="Chapter tools"
    >
      <template v-for="action in chapter.actions" :key="action.label">
        <a
          v-if="action.external"
          class="button primary"
          :href="grafanaUrl"
          target="_blank"
          rel="noopener"
          >{{ action.label }} ↗</a
        >
        <button
          v-else
          class="button"
          :class="{
            primary:
              activeView === action.tab &&
              (!action.readPath || readPath === action.readPath),
          }"
          :aria-pressed="
            activeView === action.tab &&
            (!action.readPath || readPath === action.readPath)
          "
          @click="act(action)"
        >
          {{ action.label }}
        </button>
      </template>
      <button
        v-if="
          selectedId && ['submit', 'enrich', 'recover'].includes(chapter.id)
        "
        class="button"
        :class="{ primary: activeView === 'detail' }"
        :aria-pressed="activeView === 'detail'"
        @click="inspect(selectedId)"
      >
        Inspect ticket #{{ selectedId }}
      </button>
    </div>
    <ReadPathControl
      v-if="chapter.id === 'cache'"
      :model-value="readPath"
      :actual-path="actualPath"
      @update:model-value="emit('update:readPath', $event)"
    />
    <KeepAlive>
      <SampleDataPanel
        v-if="activeView === 'samples'"
        :key="chapter.id"
        :launch="sampleLaunch"
        :snapshot="snapshot"
        @created="(id) => (selectedId = id)"
        @updated="emit('updated')"
        @select="inspect"
      />
    </KeepAlive>
    <KeepAlive>
      <TicketWorkspace
        v-if="activeView === 'tickets' || activeView === 'review'"
        :key="chapter.id"
        :tickets="tickets"
        :snapshot="snapshot"
        :refreshed-at="refreshedAt"
        :review-mode="activeView === 'review'"
        :initial-id="activeView === 'review' ? reviewId : selectedId"
        @updated="emit('updated')"
        @select="(id) => (selectedId = id)"
      />
    </KeepAlive>
    <FailuresPanel
      v-if="activeView === 'failures'"
      :failures="failures"
      @updated="emit('updated')"
      @select="inspect"
      @replayed="(event) => (selectedId = event.ticketId)"
    />
    <TicketDetail
      v-if="activeView === 'detail' && selectedId"
      :ticket-id="selectedId"
      :snapshot="snapshot"
      :refreshed-at="refreshedAt"
      @updated="emit('updated')"
      @select="inspect"
    />
    <p v-if="chapter.id === 'observe'" class="alert info">
      Use the live counts below to orient yourself, then open Grafana for
      traces, event metrics, and connection pool activity. Grafana opens in a
      separate tab so you can keep this chapter alongside it.
    </p>
  </section>
  <section
    class="panel padded walkthrough-snapshot"
    aria-label="Current lab snapshot"
  >
    <div class="section-heading">
      <div>
        <div class="eyebrow">CURRENT LAB SNAPSHOT</div>
        <h3>Check your lab’s current state</h3>
      </div>
      <span class="subtle-tag">Refreshes with the console</span>
    </div>
    <div class="walkthrough-observations">
      <p>
        <strong>{{ count("support_ticket") }}</strong> tickets
      </p>
      <p>
        <strong>{{ count("ticket_assistance") }}</strong> saved summaries
      </p>
      <p>
        <strong>{{
          failures.filter((failure) => failure.replayable).length
        }}</strong>
        replayable failures
      </p>
      <p>
        <strong>{{ count("ticket_approval_history") }}</strong> review snapshots
      </p>
      <p>
        <strong
          >{{ snapshot.policies.filter((policy) => policy.indexed).length }} /
          {{ snapshot.policies.length }}</strong
        >
        policies indexed
      </p>
      <p>
        <strong>{{ actualPath || "No list read yet" }}</strong> last list read
      </p>
    </div>
    <p class="small muted">
      These are current counts across the whole lab, not proof that a chapter
      completed. {{ tickets.length }} tickets are visible on the selected list
      read path; cached data may lag. Check Grafana for service health.
    </p>
  </section>
  <nav class="walkthrough-pagination" aria-label="Chapter navigation">
    <button
      class="text-button"
      :disabled="step === 0"
      @click="emit('update:step', step - 1)"
    >
      ← Previous chapter
    </button>
    <button
      v-if="step < walkthrough.length - 1"
      class="button primary"
      @click="emit('update:step', step + 1)"
    >
      Next: {{ walkthrough[step + 1].short }} →
    </button>
    <span v-else class="small muted"
      >You’ve reached the final chapter. Revisit any chapter to keep
      exploring.</span
    >
  </nav>
  <details class="walkthrough-reference">
    <summary>
      Component reference, all eight tables, and the policy corpus
    </summary>
    <ComponentsPanel
      :snapshot="snapshot"
      :actual-path="actualPath"
      :grafana-url="grafanaUrl"
    />
  </details>
</template>
