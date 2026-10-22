<script setup>
import { computed } from "vue";

const props = defineProps({ code: { type: String, required: true } });

// A small grammar for the walkthrough's pseudocode, rather than a Java/JS parser.
// Render tokens as text so code never becomes HTML.
const tokens = computed(() => {
  const pattern = /(?<comment>\/\/[^\n]*)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?<number>\b\d+(?:\.\d+)?s?\b)|(?<function>\b[A-Za-z_]\w*(?=\s*\())|(?<keyword>\b(?:on|for|if|or|with|try|catch|begin|commit|abort|return|require|save|insert|update|set|send|publish|subscribe|start|ensure|validate|inject|restore|observe|record|log|append|lock|mark|reset|retry|skip|acknowledge|using|in|after)\b)|(?<constant>\b[A-Z][A-Z_\d]+\b)|(?<operator>[→=+])/g;
  const result = [];
  let offset = 0;
  for (const match of props.code.matchAll(pattern)) {
    if (match.index > offset) {
      result.push({ text: props.code.slice(offset, match.index) });
    }
    result.push({
      text: match[0],
      type: Object.keys(match.groups).find((key) => match.groups[key] !== undefined),
    });
    offset = match.index + match[0].length;
  }
  if (offset < props.code.length) result.push({ text: props.code.slice(offset) });
  return result;
});
</script>

<template>
  <pre class="pseudocode-block"><code><span
    v-for="(token, index) in tokens"
    :key="index"
    :class="token.type && `syntax-${token.type}`"
  >{{ token.text }}</span></code></pre>
</template>

<style scoped>
.pseudocode-block {
  margin: 0;
  padding: 20px;
  border: 1px solid #334155;
  border-radius: 10px;
  background: #0f172a;
  color: #e2e8f0;
  color-scheme: dark;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  font: 14px/1.7 ui-monospace, monospace;
  tab-size: 2;
}
.pseudocode-block code {
  font: inherit;
  color: inherit;
}
.syntax-comment { color: #94a3b8; }
.syntax-string { color: #a5d6a7; }
.syntax-number { color: #fdba74; }
.syntax-function { color: #7dd3fc; }
.syntax-keyword { color: #c4b5fd; }
.syntax-constant { color: #fcd34d; }
.syntax-operator { color: #67e8f9; }
.pseudocode-block ::selection {
  background: #334e78;
  color: #ffffff;
}
</style>
