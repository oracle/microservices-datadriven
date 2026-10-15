<script setup>
import { computed, ref } from "vue";
import { diagrams } from "../diagrams";
const category = ref("All diagrams"),
  mode = ref("presentation"),
  activeId = ref(14);
const filtered = computed(() =>
  diagrams.filter(
    (d) => category.value === "All diagrams" || d.category === category.value,
  ),
);
const activeIndex = computed(() =>
  Math.max(
    0,
    filtered.value.findIndex((d) => d.id === activeId.value),
  ),
);
const current = computed(() => filtered.value[activeIndex.value]);
function advance(offset) {
  activeId.value =
    filtered.value[
      (activeIndex.value + offset + filtered.value.length) %
        filtered.value.length
    ].id;
}
function present(diagram) {
  activeId.value = diagram.id;
  mode.value = "presentation";
}
function brief(text) {
  return text.length > 240
    ? `${text.slice(0, 237).replace(/\s+\S*$/, "")}…`
    : text;
}
</script>
<template>
  <div class="diagram-tools">
    <label class="sr-only" for="diagram-category">Diagram category</label
    ><select id="diagram-category" v-model="category">
      <option>All diagrams</option>
      <option>Workflow</option>
      <option>Schema</option>
      <option>Context</option></select
    ><label class="sr-only" for="diagram-mode">Gallery layout</label
    ><select id="diagram-mode" v-model="mode">
      <option value="presentation">Presentation view</option>
      <option value="grid">Browse gallery</option></select
    ><a
      class="text-button"
      href="/diagrams/index.html"
      target="_blank"
      rel="noopener"
      >Original scrolling gallery ↗</a
    >
  </div>
  <p class="page-intro">
    Explore the implementation through {{ diagrams.length }} diagrams. Workflow
    and schema chapters describe the running lab; regional placement is a
    deployment concept.
  </p>
  <div
    v-if="mode === 'presentation' && current"
    class="diagram-stage"
    @keydown.left="advance(-1)"
    @keydown.right="advance(1)"
  >
    <a
      :href="current.file"
      target="_blank"
      rel="noopener"
      :aria-label="`Open ${current.title} at full size`"
      ><img :key="current.id" :src="current.file" :alt="current.title"
    /></a>
    <div class="stage-controls">
      <button class="button" aria-label="Previous diagram" @click="advance(-1)">
        ←
      </button>
      <div aria-live="polite">
        <div class="diagram-number">
          {{ String(activeIndex + 1).padStart(2, "0") }} /
          {{ filtered.length }} · {{ current.category }}
        </div>
        <h3>{{ current.title }}</h3>
      </div>
      <button class="button" aria-label="Next diagram" @click="advance(1)">
        →
      </button>
    </div>
    <p>{{ brief(current.description) }}</p>
    <details v-if="current.description.length > 240">
      <summary>Read the full explanation</summary>
      <p>{{ current.description }}</p>
    </details>
    <a :href="current.file" target="_blank" rel="noopener"
      >Open SVG at full size ↗</a
    >
  </div>
  <div v-else class="diagram-grid">
    <article
      v-for="diagram in filtered"
      :key="diagram.id"
      class="panel diagram-card"
    >
      <a :href="diagram.file" target="_blank" rel="noopener"
        ><img :src="diagram.file" :alt="diagram.title" loading="lazy"
      /></a>
      <div class="diagram-caption">
        <div class="split">
          <span class="diagram-number"
            >{{ String(diagram.id).padStart(2, "0") }} /
            {{ diagram.category }}</span
          ><button class="text-button" @click="present(diagram)">
            Present ↗
          </button>
        </div>
        <h3>{{ diagram.title }}</h3>
        <p>{{ brief(diagram.description) }}</p>
        <details v-if="diagram.description.length > 240">
          <summary>Read the full explanation</summary>
          <p>{{ diagram.description }}</p>
        </details>
      </div>
    </article>
  </div>
</template>
