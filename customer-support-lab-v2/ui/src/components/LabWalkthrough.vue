<script setup>
import { computed, ref, watch, onUnmounted } from "vue";
import { walkthrough } from "../walkthrough";
import ComponentsPanel from "./ComponentsPanel.vue";
import WalkthroughDiagram from "./WalkthroughDiagram.vue";
const props = defineProps({
  snapshot: Object,
  tickets: Array,
  failures: Array,
  actualPath: String,
  grafanaUrl: String,
  step: Number,
});
const emit = defineEmits(["action", "update:step"]);
const chapter = computed(() => walkthrough[props.step]);
const missing = computed(() =>
  chapter.value.requires.filter(
    (profile) => !props.snapshot.profiles.includes(profile),
  ),
);
const playing = ref(false);
const diagramStep = ref(props.step);
let timer;
watch(
  () => props.step,
  (value) => {
    diagramStep.value = value;
    playing.value = false;
  },
);
watch(playing, (value) => {
  clearInterval(timer);
  if (value)
    timer = setInterval(() => {
      diagramStep.value = (diagramStep.value + 1) % walkthrough.length;
    }, 4500);
});
onUnmounted(() => clearInterval(timer));
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
        chapter, see the handoff, then try it yourself. Return here between
        actions; your selected chapter stays in place.
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
  <nav class="walkthrough-chapters" aria-label="Walkthrough chapters">
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
      <p v-if="missing.length" class="alert info" role="status">
        To try this chapter, restart Maven with the missing profiles:
        {{ missing.join(", ") }}. You can still explore the illustration.
      </p>
      <div class="walkthrough-actions">
        <template v-for="action in chapter.actions" :key="action.label"
          ><a
            v-if="action.external"
            class="button primary"
            :href="grafanaUrl"
            target="_blank"
            rel="noopener"
            >{{ action.label }} ↗</a
          ><button
            v-else
            class="button"
            :disabled="!!missing.length"
            @click="emit('action', action)"
          >
            {{ action.label }} →
          </button></template
        >
      </div>
      <p class="small muted">
        Actions open the real screens. Submit, review, and replay only when you
        choose to; those operations write lab data and may call OCI.
      </p>
      <div class="walkthrough-pagination">
        <button
          class="text-button"
          :disabled="step === 0"
          @click="emit('update:step', step - 1)"
        >
          ← Previous chapter</button
        ><button
          class="text-button"
          :disabled="step === walkthrough.length - 1"
          @click="emit('update:step', step + 1)"
        >
          Next chapter →
        </button>
      </div>
    </section>
    <section
      class="panel walkthrough-illustration"
      aria-label="Simulated component interactions"
    >
      <div class="walkthrough-diagram-heading">
        <div>
          <span class="subtle-tag">SIMULATED FLOW</span>
          <p class="small muted">
            {{
              playing
                ? "Playing an illustrated tour"
                : diagramStep === step
                  ? "Illustrating your selected chapter"
                  : "Paused illustrated tour"
            }}
            · not live telemetry
          </p>
        </div>
        <button
          class="button"
          :aria-pressed="playing"
          @click="playing = !playing"
        >
          {{ playing ? "Pause simulation" : "Play simulation" }}
        </button>
      </div>
      <WalkthroughDiagram
        :chapter="walkthrough[diagramStep]"
        :playing="playing"
      />
      <div class="walkthrough-diagram-caption" aria-live="off">
        <strong>{{ walkthrough[diagramStep].title }}</strong>
        <p>{{ walkthrough[diagramStep].summary }}</p>
      </div>
    </section>
  </div>
  <section
    class="panel padded walkthrough-snapshot"
    aria-label="Current lab snapshot"
  >
    <div class="section-heading">
      <div>
        <div class="eyebrow">CURRENT LAB SNAPSHOT</div>
        <h3>Compare the illustration with your lab</h3>
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
      read path; cached data may lag. Profile badges above describe
      configuration, not service health.
    </p>
  </section>
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
