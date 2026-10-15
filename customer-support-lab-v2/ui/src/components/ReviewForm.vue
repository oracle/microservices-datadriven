<script setup>
import { ref, watch, computed } from "vue";
import { post, request } from "../api";
const props = defineProps({
  ticket: Object,
  assistance: Object,
  enabled: Boolean,
});
const emit = defineEmits(["saved"]);
const actor = ref("demo-reviewer");
const decision = ref("REJECTED");
const reason = ref("");
const pending = ref(false);
const error = ref("");
const notice = ref("");
let retry = null;
const eligible = computed(
  () =>
    props.enabled &&
    props.ticket.workflowStatus === "ENRICHED" &&
    props.assistance,
);
watch(
  () => props.ticket.id,
  () => {
    reason.value = "";
    error.value = "";
    notice.value = "";
    retry = null;
  },
);
watch(
  () => [actor.value, decision.value, reason.value],
  () => {
    retry = null;
    error.value = "";
  },
);
async function submit() {
  const ticketId = props.ticket.id;
  const reviewedGeneration = props.assistance.generatedAt;
  pending.value = true;
  error.value = "";
  notice.value = "";
  try {
    // Preserve the exact action after an uncertain response so retry cannot publish twice.
    if (!retry) {
      const current = (await request(`/tickets/${ticketId}/assistance`))
        .data;
      if (current.generatedAt !== reviewedGeneration)
        throw new Error(
          "A new summary is available. Refresh and review it before submitting.",
        );
      retry = {
        actionId: crypto.randomUUID(),
        decision: decision.value,
        actorId: actor.value.trim(),
        reason: reason.value.trim() || null,
      };
    }
    const result = await post(`/tickets/${ticketId}/approvals`, retry);
    const rejected = result.data.decision === "REJECTED";
    retry = null;
    reason.value = "";
    notice.value = rejected
      ? "Feedback saved. A revision has been requested through TxEventQ."
      : "Summary approved. Your review snapshot is saved.";
    emit("saved");
  } catch (e) {
    error.value = e.message;
  } finally {
    pending.value = false;
  }
}
</script>
<template>
  <section class="review-box">
    <div class="eyebrow">HUMAN IN THE LOOP</div>
    <h3>Review this summary</h3>
    <p v-if="!enabled" class="muted">
      Enable events, ai, and blockchain to submit reviews.
    </p>
    <p v-else-if="!eligible" class="muted">
      Review is available when the ticket reaches ENRICHED. The last saved
      summary stays visible during regeneration.
    </p>
    <form v-else @submit.prevent="submit">
      <fieldset :disabled="pending">
        <label
          >Reviewer<input
            v-model="actor"
            required
            maxlength="128"
            placeholder="Your reviewer ID"
        /></label>
        <div class="decision-options">
          <label :class="{ selected: decision === 'REJECTED' }"
            ><input v-model="decision" type="radio" value="REJECTED" />Request
            revision</label
          >
          <label :class="{ selected: decision === 'APPROVED' }"
            ><input
              v-model="decision"
              type="radio"
              value="APPROVED"
            />Approve</label
          >
        </div>
        <label
          >{{
            decision === "REJECTED"
              ? "Feedback for the revised summary"
              : "Review note (optional)"
          }}
          <textarea
            v-model="reason"
            :required="decision === 'REJECTED'"
            maxlength="1000"
            rows="4"
            :placeholder="
              decision === 'REJECTED'
                ? 'What should the summary correct or include?'
                : 'Why does this summary look right?'
            "
          />
        </label>
        <div class="split">
          <span class="muted small">{{ reason.length }}/1000</span
          ><button
            class="button primary"
            :disabled="
              !actor.trim() || (decision === 'REJECTED' && !reason.trim())
            "
          >
            {{
              pending
                ? "Saving…"
                : decision === "REJECTED"
                  ? "Send feedback & regenerate"
                  : "Approve summary"
            }}
          </button>
        </div>
      </fieldset>
    </form>
    <p v-if="error" class="alert error" role="alert">
      {{ error }} You can retry the unchanged action safely.
    </p>
    <p v-if="notice" class="alert success" role="status">{{ notice }}</p>
    <p class="small muted">
      Rejection regenerates assistance using your feedback. Approval accepts the
      current summary. Reviewer IDs are self-declared in this local demo.
    </p>
  </section>
</template>
