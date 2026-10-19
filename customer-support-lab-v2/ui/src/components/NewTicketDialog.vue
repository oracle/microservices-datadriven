<script setup>
import { ref } from "vue";
import { post } from "../api";
const emit = defineEmits(["created"]);
const dialog = ref(null),
  title = ref(""),
  description = ref(""),
  failOnce = ref(false),
  pending = ref(false),
  error = ref("");
defineExpose({
  open() {
    error.value = "";
    dialog.value.showModal();
  },
});
async function submit() {
  pending.value = true;
  error.value = "";
  try {
    const payload = {
      title: (failOnce.value ? "[demo-fail-once] " : "") + title.value.trim(),
      description: description.value.trim(),
    };
    const { data } = await post("/tickets", payload);
    dialog.value.close();
    title.value = "";
    description.value = "";
    failOnce.value = false;
    emit("created", data.id);
  } catch (e) {
    error.value = `${e.message} A submission may have committed if the response was lost. Check the ticket list before resubmitting.`;
  } finally {
    pending.value = false;
  }
}
</script>
<template>
  <dialog
    ref="dialog"
    class="new-ticket-dialog"
    @cancel="pending && $event.preventDefault()"
  >
    <div class="split">
      <div class="eyebrow">START A WORKFLOW</div>
      <button
        class="icon-button"
        aria-label="Close new ticket"
        :disabled="pending"
        @click="dialog.close()"
      >
        ×
      </button>
    </div>
    <h2>New support ticket</h2>
    <p class="muted">
      Submission saves the ticket and publishes its event together. Enrichment
      happens asynchronously.
    </p>
    <form @submit.prevent="submit">
      <fieldset :disabled="pending">
        <label
          >Title<input
            v-model="title"
            autofocus
            required
            :maxlength="failOnce ? 238 : 255"
            placeholder="Lost MFA authenticator" /></label
        ><label
          >Description<textarea
            v-model="description"
            required
            maxlength="2000"
            rows="5"
            placeholder="Describe the issue and what the customer needs help with…"
          />
        </label>
        <label class="checkbox-label"
          ><input v-model="failOnce" type="checkbox" />Trigger the deliberate
          failure/replay demo</label
        >
        <p v-if="error" class="alert error" role="alert">{{ error }}</p>
        <div class="dialog-actions">
          <button type="button" class="button" @click="dialog.close()">
            Cancel</button
          ><button
            class="button primary"
            :disabled="!title.trim() || !description.trim()"
          >
            {{ pending ? "Creating…" : "Create ticket →" }}
          </button>
        </div>
      </fieldset>
    </form>
  </dialog>
</template>
