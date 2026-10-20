<script setup>
import StatusBadge from "./StatusBadge.vue";
import { formatTime } from "../api";
defineProps({ history: Array });
</script>
<template>
  <section>
    <details class="disclosure">
      <summary>Review history · {{ history.length }} snapshots</summary>
      <p v-if="!history.length" class="empty compact">
        No human reviews recorded for this ticket.
      </p>
      <ol v-else class="history">
        <li v-for="review in [...history].reverse()" :key="review.actionId">
          <div class="split">
            <StatusBadge :value="review.decision" /><time>{{
              formatTime(review.decidedAt)
            }}</time>
          </div>
          <p>
            <strong>{{ review.actorId }}</strong
            ><span v-if="review.reason"> · {{ review.reason }}</span>
          </p>
          <details>
            <summary>Reviewed assistance &amp; integrity details</summary>
            <blockquote class="pre-wrap">{{ review.reviewedSummary }}</blockquote>
            <dl class="metadata">
              <dt>Model / prompt</dt>
              <dd>{{ review.summaryModel }} / {{ review.promptVersion }}</dd>
              <dt>Action UUID</dt>
              <dd class="mono">{{ review.actionId }}</dd>
              <dt>Assistance SHA-256</dt>
              <dd class="mono">{{ review.summaryDigest }}</dd>
            </dl>
        </details>
      </li>
    </ol>
    </details>
  </section>
</template>
