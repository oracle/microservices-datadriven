<script setup>
import { computed, ref, watch } from "vue";
import { needsReview } from "../api";
import StatusBadge from "./StatusBadge.vue";
import TicketDetail from "./TicketDetail.vue";
const props = defineProps({
  tickets: Array,
  snapshot: Object,
  refreshedAt: Date,
  reviewMode: Boolean,
  initialId: Number,
});
const emit = defineEmits(["updated"]);
const query = ref(""),
  filter = ref(props.reviewMode ? "REVIEW" : "ALL"),
  selected = ref(props.initialId || null);
const filtered = computed(() =>
  props.tickets.filter((t) => {
    const text = `${t.id} ${t.title} ${t.description}`.toLowerCase();
    return (
      text.includes(query.value.toLowerCase()) &&
      (filter.value === "ALL" ||
        (filter.value === "REVIEW"
          ? needsReview(t, props.snapshot)
          : t.workflowStatus === filter.value))
    );
  }),
);
watch(
  () => props.initialId,
  (id) => {
    if (id) {
      selected.value = id;
      filter.value = "ALL";
      query.value = "";
    }
  },
);
watch(
  filtered,
  (rows) => {
    if (!selected.value && rows.length) selected.value = rows[0].id;
  },
  { immediate: true },
);
function selectRelated(id) {
  selected.value = id;
  filter.value = "ALL";
  query.value = "";
}
</script>
<template>
  <div v-if="reviewMode && !snapshot?.reviewEnabled" class="alert info">
    Human review requires the events, ai, and blockchain profiles. You can still
    inspect tickets and saved assistance.
  </div>
  <div class="workspace">
    <section class="ticket-list panel">
      <div class="list-controls">
        <label class="sr-only" for="ticket-search">Search tickets</label
        ><input
          id="ticket-search"
          v-model="query"
          type="search"
          placeholder="Search tickets…"
        />
        <label class="sr-only" for="status-filter">Filter tickets</label
        ><select id="status-filter" v-model="filter">
          <option value="ALL">All tickets</option>
          <option v-if="reviewMode" value="REVIEW">Needs review</option>
          <option
            v-for="status in ['RECEIVED', 'TRIAGED', 'ENRICHED', 'FAILED']"
            :key="status"
            :value="status"
          >
            {{ status[0] + status.slice(1).toLowerCase() }}
          </option>
        </select>
      </div>
      <div class="list-caption">
        {{ filtered.length }} {{ filtered.length === 1 ? "ticket" : "tickets"
        }}<span>{{ reviewMode ? "Saved summaries" : "Latest IDs first" }}</span>
      </div>
      <div v-if="!filtered.length" class="empty">
        <strong>{{
          reviewMode ? "No tickets need attention here." : "No tickets found."
        }}</strong>
        <p>
          {{
            reviewMode
              ? "An approved summary leaves Needs review. Switch to All tickets to view its history."
              : "Create a ticket or change your filters."
          }}
        </p>
      </div>
      <button
        v-for="ticket in filtered"
        :key="ticket.id"
        class="ticket-row"
        :class="{ selected: selected === ticket.id }"
        :aria-pressed="selected === ticket.id"
        @click="selected = ticket.id"
      >
        <div class="split">
          <span class="ticket-id">#{{ ticket.id }}</span
          ><StatusBadge :value="ticket.workflowStatus" />
        </div>
        <strong>{{ ticket.title }}</strong>
        <p>{{ ticket.description }}</p>
        <span
          v-if="reviewMode && needsReview(ticket, snapshot)"
          class="review-hint"
          >● Ready for human review</span
        >
      </button>
    </section>
    <TicketDetail
      v-if="selected"
      :ticket-id="selected"
      :snapshot="snapshot"
      :refreshed-at="refreshedAt"
      :review-mode="reviewMode"
      @updated="emit('updated')"
      @select="selectRelated"
    />
    <div v-else class="panel empty detail-placeholder">
      <span class="placeholder-icon">▤</span>
      <h3>Your workflow, in detail</h3>
      <p>
        Select a ticket to see its summary, matches, feedback, and review
        history.
      </p>
    </div>
  </div>
</template>
