<script setup>
const steps = [
  {
    title: "Receive",
    text: "Ticket + event commit together",
    number: "01",
  },
  {
    title: "Enrich",
    text: "Embed · retrieve · summarize",
    number: "02",
  },
  {
    title: "Review",
    text: "Human decision + saved snapshot",
    number: "03",
  },
  {
    title: "Revise",
    text: "Feedback event regenerates assistance",
    number: "04",
  },
];
</script>
<template>
  <div class="flow" aria-label="Ticket event flow">
    <div v-for="step in steps" :key="step.number" class="flow-step">
      <span class="step-number">{{ step.number }}</span
      ><strong>{{ step.title }}</strong>
      <p>{{ step.text }}</p>
    </div>
  </div>
  <div class="flow-note">
    <span>↳</span> Rejection loops back through TxEventQ. Approval accepts the
    saved assistance. Failed events can be replayed.
  </div>
</template>
