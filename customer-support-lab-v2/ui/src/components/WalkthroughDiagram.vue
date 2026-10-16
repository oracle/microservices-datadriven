<script setup>
defineProps({ chapter: Object, playing: Boolean });
const nodes = [
  { id: "ui", x: 44, y: 72, label: "Vue console", detail: "Human actions" },
  { id: "app", x: 304, y: 72, label: "Spring Boot", detail: "HTTP API + UCP" },
  {
    id: "telemetry",
    x: 566,
    y: 72,
    label: "Grafana LGTM",
    detail: "Traces + metrics",
  },
  {
    id: "data",
    x: 68,
    y: 240,
    label: "Ticket tables",
    detail: "State + assistance",
  },
  { id: "queue", x: 288, y: 240, label: "TxEventQ", detail: "OKafka API" },
  {
    id: "worker",
    x: 566,
    y: 240,
    label: "Event consumer",
    detail: "Inside Spring Boot",
  },
  {
    id: "vector",
    x: 68,
    y: 390,
    label: "Vector retrieval",
    detail: "Tickets + policies",
  },
  {
    id: "history",
    x: 288,
    y: 390,
    label: "Review history",
    detail: "Version snapshots",
  },
  {
    id: "ai",
    x: 566,
    y: 390,
    label: "OCI Generative AI",
    detail: "Embed + summarize",
  },
  {
    id: "cache",
    x: 566,
    y: 510,
    label: "True Cache",
    detail: "Read-only · redo",
  },
];
const edges = [
  { id: "submit", d: "M224 102H304" },
  { id: "write", d: "M349 132V173H158V240" },
  { id: "publish", d: "M248 270H288" },
  { id: "consume", d: "M468 270H566" },
  { id: "generate", d: "M656 300V390" },
  { id: "retrieve", d: "M586 300V354H270V420H248" },
  { id: "save", d: "M610 300V334H158V300" },
  { id: "review", d: "M438 132V173H520V357H378V390" },
  { id: "revise", d: "M378 390V300" },
  { id: "redo", d: "M68 270H32V540H566" },
  { id: "cache-read", d: "M484 114H768V540H746" },
  { id: "app-telemetry", d: "M484 102H566" },
  { id: "worker-telemetry", d: "M701 240V132" },
];
</script>
<template>
  <svg
    class="walkthrough-diagram"
    data-role="diagram"
    :class="{ playing }"
    width="800"
    height="600"
    viewBox="0 0 800 600"
    role="img"
    aria-labelledby="walkthrough-diagram-title walkthrough-diagram-description"
  >
    <title id="walkthrough-diagram-title">
      Support lab component interactions
    </title>
    <desc id="walkthrough-diagram-description">
      Simulated architecture. The highlighted flow illustrates
      {{ chapter.title }}: {{ chapter.mechanism }} Arrows illustrate
      interactions, not live traffic. TxEventQ, vector retrieval, ticket tables,
      and review history are inside Oracle AI Database. The consumer runs inside
      Spring Boot.
    </desc>
    <defs>
      <marker
        id="walkthrough-arrow"
        viewBox="0 0 10 10"
        refX="8"
        refY="5"
        markerWidth="5"
        markerHeight="5"
        orient="auto-start-reverse"
      >
        <path d="M0 0L10 5L0 10Z" fill="context-stroke" />
      </marker>
    </defs>
    <rect
      x="44"
      y="196"
      width="450"
      height="292"
      rx="18"
      fill="#edf3eb"
      stroke="#c4d4c5"
    />
    <text
      x="66"
      y="224"
      font-family="Arial, Helvetica, sans-serif"
      font-size="18"
      font-weight="600"
      fill="#376846"
    >
      Oracle AI Database
    </text>
    <g
      fill="none"
      stroke="#c0cbc3"
      stroke-width="2"
      marker-end="url(#walkthrough-arrow)"
    >
      <path
        v-for="edge in edges"
        :key="edge.id"
        :d="edge.d"
        :class="{ 'flow-active': chapter.edges.includes(edge.id) }"
      />
    </g>
    <g
      v-for="node in nodes"
      :key="node.id"
      :class="[
        'walkthrough-node',
        { 'node-active': chapter.nodes.includes(node.id) },
      ]"
    >
      <rect
        :x="node.x"
        :y="node.y"
        width="180"
        height="60"
        rx="10"
        fill="#fff"
        stroke="#ced9d0"
        stroke-width="2"
      />
      <text
        :x="node.x + 90"
        :y="node.y + 25"
        text-anchor="middle"
        font-family="Arial, Helvetica, sans-serif"
        font-size="18"
        font-weight="600"
        fill="#263d37"
      >
        {{ node.label }}
      </text>
      <text
        :x="node.x + 90"
        :y="node.y + 47"
        text-anchor="middle"
        font-family="Arial, Helvetica, sans-serif"
        font-size="18"
        font-weight="400"
        fill="#576b61"
      >
        {{ node.detail }}
      </text>
    </g>
    <text
      x="44"
      y="44"
      font-family="Arial, Helvetica, sans-serif"
      font-size="18"
      font-weight="600"
      fill="#376846"
    >
      {{ chapter.title }}
    </text>
    <text
      x="44"
      y="565"
      font-family="Arial, Helvetica, sans-serif"
      font-size="18"
      font-weight="400"
      fill="#576b61"
    >
      Illustrated flow · no requests are sent by this diagram
    </text>
  </svg>
</template>
