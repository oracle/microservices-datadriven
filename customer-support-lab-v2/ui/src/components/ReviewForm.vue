<script setup>
import { ref, watch, computed } from "vue";
import { post, request } from "../api";
const props = defineProps({
  ticket: Object,
  assistance: Object,
  enabled: Boolean,
  initialFeedback: { type: String, default: "" },
});
const emit = defineEmits(["saved", "busy"]);
const actor = ref("demo-reviewer");
const decision = ref("REJECTED");
const reason = ref(props.initialFeedback);
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
    reason.value = props.initialFeedback;
    error.value = "";
    notice.value = "";
    retry = null;
  },
);
watch(
  () => props.initialFeedback,
  (value) => {
    if (!pending.value) {
      reason.value = value;
      decision.value = "REJECTED";
    }
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
  emit("busy", true);
  error.value = "";
  notice.value = "";
  try {
    // Preserve the exact action after an uncertain response so retry cannot publish twice.
    if (!retry) {
      const current = (await request(`/tickets/${ticketId}/assistance`)).data;
      if (current.generatedAt !== reviewedGeneration)
        throw new Error(
          "New assistance is available. Refresh and review it before submitting.",
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
      : "Assistance approved. Your review snapshot is saved.";
    emit("saved", result.data);
  } catch (e) {
    error.value = e.message;
  } finally {
    pending.value = false;
    emit("busy", false);
  }
}
</script>
<template>
  <section class="review-box">
    <div class="eyebrow">HUMAN IN THE LOOP</div>
    <h3>Review this assistance</h3>
    <p v-if="!enabled" class="muted">
      Enable events, ai, and blockchain to submit reviews.
    </p>
    <p v-else-if="!eligible" class="muted">
      Review is available when the ticket reaches ENRICHED. The last saved
      assistance stays visible during regeneration.
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
              ? "Feedback for the revised assistance"
              : "Review note (optional)"
          }}
          <textarea
            v-model="reason"
            :required="decision === 'REJECTED'"
            maxlength="1000"
            rows="4"
            :placeholder="
              decision === 'REJECTED'
                ? 'What should the summary or suggested resolution correct?'
                : 'Why does this assistance look right?'
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
                  : "Approve assistance"
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
      current summary and suggested resolution. Reviewer IDs are self-declared in this local demo.
    </p>
  </section>
</template>
