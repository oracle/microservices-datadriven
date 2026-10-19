<script setup>
defineProps({ modelValue: String, actualPath: String });
defineEmits(["update:modelValue"]);
</script>
<template>
  <div class="read-controls">
    <label class="small muted">
      Ticket list read path
      <select
        :value="modelValue"
        @change="$emit('update:modelValue', $event.target.value)"
      >
        <option value="primary">Primary · fresh</option>
        <option value="cache">True Cache · may lag</option>
      </select>
    </label>
    <span class="small muted">
      Served by <strong>{{ actualPath || "—" }}</strong
      >. Ticket details and review always read primary.
    </span>
  </div>
</template>
