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
const emit = defineEmits(["updated", "select"]);
const query = ref(""),
  filter = ref(props.reviewMode ? "REVIEW" : "ALL"),
  selected = ref(props.initialId || null);
// Hide a committed approval immediately, even while the workspace refresh is in flight.
// A later summary generation becomes eligible again.
const approvedGenerations = ref(new Map());
function awaitingReview(ticket) {
  const generation = props.snapshot?.reviewStates.find(
    (review) => review.ticketId === ticket.id,
  )?.generatedAt;
  const accepted = approvedGenerations.value.get(ticket.id);
  return (
    needsReview(ticket, props.snapshot) &&
    !(accepted && (!generation || accepted === generation))
  );
}
const filtered = computed(() =>
  props.tickets.filter((t) => {
    const text = `${t.id} ${t.title} ${t.description}`.toLowerCase();
    return (
      text.includes(query.value.toLowerCase()) &&
      (filter.value === "ALL" ||
        (filter.value === "REVIEW"
          ? awaitingReview(t)
          : t.workflowStatus === filter.value))
    );
  }),
);
const page = ref(0);
const pageSize = 4;
const pageCount = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize)));
const currentPage = computed(() => Math.min(page.value, pageCount.value - 1));
const visibleTickets = computed(() => filtered.value.slice(
  currentPage.value * pageSize, (currentPage.value + 1) * pageSize,
));
watch([query, filter], () => { page.value = 0; });
watch(selected, (id) => {
  const index = filtered.value.findIndex(ticket => ticket.id === id);
  if (index >= 0) page.value = Math.floor(index / pageSize);
});
watch(
  () => props.initialId,
  (id) => {
    if (id && id !== selected.value) {
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
  emit("select", id);
  filter.value = "ALL";
  query.value = "";
}
function reviewed(review) {
  if (!props.reviewMode || review.decision !== "APPROVED") return;
  approvedGenerations.value.set(review.ticketId, review.generatedAt);
  query.value = "";
  filter.value = "REVIEW";
  selected.value = props.tickets.find(awaitingReview)?.id || null;
  emit("select", selected.value);
}
</script>
<template>
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
        }}<span>{{ reviewMode ? "Saved assistance" : "Latest IDs first" }}</span>
      </div>
      <div v-if="!filtered.length" class="empty">
        <strong>{{
          reviewMode ? "No tickets need attention here." : "No tickets found."
        }}</strong>
        <p>
          {{
            reviewMode
              ? "Approved assistance leaves Needs review. Switch to All tickets to view its history."
              : "Create a ticket or change your filters."
          }}
        </p>
      </div>
      <button
        v-for="ticket in visibleTickets"
        :key="ticket.id"
        class="ticket-row"
        :class="{ selected: selected === ticket.id }"
        :aria-pressed="selected === ticket.id"
        @click="
          selected = ticket.id;
          emit('select', ticket.id);
        "
      >
        <div class="split">
          <span class="ticket-id">#{{ ticket.id }}</span
          ><StatusBadge :value="ticket.workflowStatus" />
        </div>
        <strong>{{ ticket.title }}</strong>
      </button>
      <nav v-if="pageCount > 1" class="list-pagination" aria-label="Ticket pages">
        <button class="text-button" :disabled="currentPage === 0"
          @click="page = currentPage - 1">← Previous</button>
        <span class="small" aria-live="polite">{{ currentPage + 1 }} / {{ pageCount }}</span>
        <button class="text-button" :disabled="currentPage + 1 >= pageCount"
          @click="page = currentPage + 1">Next →</button>
      </nav>
    </section>
    <TicketDetail
      v-if="selected"
      :ticket-id="selected"
      :snapshot="snapshot"
      :refreshed-at="refreshedAt"
      :review-mode="reviewMode"
      @updated="emit('updated')"
      @reviewed="reviewed"
      @select="selectRelated"
    />
    <div
      v-else-if="
        reviewMode && filter === 'REVIEW' && !query && !filtered.length
      "
      class="panel empty detail-placeholder"
      role="status"
    >
      <span class="clear-icon">✓</span>
      <h3>You're all caught up</h3>
      <p>
        No summaries are awaiting human review. New or regenerated summaries
        will appear here when they are ready.
      </p>
      <button class="text-button" @click="filter = 'ALL'">
        View all tickets and review history →
      </button>
    </div>
    <div v-else class="panel empty detail-placeholder">
      <span class="placeholder-icon">▤</span>
      <h3>Your workflow, in detail</h3>
      <p>
        Select a ticket to see its summary, suggested resolution, matches, feedback, and review
        history.
      </p>
    </div>
  </div>
</template>
