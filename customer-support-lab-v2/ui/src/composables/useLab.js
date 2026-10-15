import { ref, computed, onMounted, onUnmounted } from "vue";
import { request, needsReview } from "../api";

export function useLab() {
  const snapshot = ref(null);
  const tickets = ref([]);
  const failures = ref([]);
  const error = ref("");
  const loading = ref(false);
  const refreshedAt = ref(null);
  const readPath = ref("primary");
  const actualPath = ref("");
  const autoRefresh = ref(true);
  const ready = computed(() =>
    tickets.value.filter((t) => needsReview(t, snapshot.value)),
  );
  const eventsEnabled = computed(() =>
    snapshot.value?.profiles.includes("events"),
  );
  let timer;

  async function refresh() {
    if (loading.value) return;
    loading.value = true;
    try {
      const info = (await request("/api/lab")).data;
      let all = [],
        failed = [];
      if (info.profiles.includes("events")) {
        const results = await Promise.all([
          request(`/tickets?readPath=${readPath.value}`),
          request("/ticket-events/failures"),
        ]);
        all = results[0].data;
        failed = results[1].data;
        actualPath.value = results[0].readPath;
      }
      snapshot.value = info;
      tickets.value = all.sort((a, b) => b.id - a.id);
      failures.value = failed;
      error.value = "";
      refreshedAt.value = new Date();
    } catch (e) {
      error.value = `${e.message} Check that the Spring application is running and the Vite API proxy points to it. Displayed data may be stale.`;
    } finally {
      loading.value = false;
    }
  }

  onMounted(() => {
    refresh();
    timer = setInterval(() => {
      if (autoRefresh.value && !document.hidden) refresh();
    }, 5000);
  });
  onUnmounted(() => clearInterval(timer));
  return {
    snapshot,
    tickets,
    failures,
    error,
    loading,
    refreshedAt,
    readPath,
    actualPath,
    autoRefresh,
    ready,
    eventsEnabled,
    refresh,
  };
}
