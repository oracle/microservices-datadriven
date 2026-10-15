<script setup>
defineProps({ value: String });
</script>
<template>
  <span class="badge" :class="(value || '').toLowerCase()"
    ><span class="badge-dot"></span
    >{{ (value || "Unknown").replaceAll("_", " ") }}</span
  >
</template>
