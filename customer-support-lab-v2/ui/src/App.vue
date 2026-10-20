<script setup>
import { computed, ref, watch } from "vue";
import { useLab } from "./composables/useLab";
import ReadPathControl from "./components/ReadPathControl.vue";
import OverviewPanel from "./components/OverviewPanel.vue";
import TicketWorkspace from "./components/TicketWorkspace.vue";
import FailuresPanel from "./components/FailuresPanel.vue";
import LabWalkthrough from "./components/LabWalkthrough.vue";
import DiagramsPanel from "./components/DiagramsPanel.vue";
import NewTicketDialog from "./components/NewTicketDialog.vue";
import SampleDataPanel from "./components/SampleDataPanel.vue";
const {
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
  refresh,
} = useLab();
const tabs = [
  {
    id: "overview",
    title: "Overview",
    icon: "◫",
    subtitle: "Your support workflow, at a glance.",
  },
  {
    id: "walkthrough",
    title: "Lab Walkthrough",
    icon: "⬡",
    subtitle:
      "Follow a request through every component, then try each handoff.",
  },
  {
    id: "tickets",
    title: "Tickets",
    icon: "▤",
    subtitle: "Inspect requests, saved assistance, and review history.",
  },
  {
    id: "review",
    title: "Human Review",
    icon: "✓",
    subtitle: "Bring human judgment into the feedback loop.",
  },
  {
    id: "failures",
    title: "Failed Events",
    icon: "↻",
    subtitle: "Inspect failures and recover work through replay.",
  },
  {
    id: "samples",
    title: "Sample Data",
    icon: "⊕",
    subtitle: "Create sample tickets and publish lab scenarios.",
  },
  {
    id: "diagrams",
    title: "Diagrams",
    icon: "◇",
    subtitle: "Walk through the architecture, schema, and complete event loop.",
  },
];
const tabFromHash = () =>
  location.hash.slice(1) === "components"
    ? "walkthrough"
    : location.hash.slice(1);
const initialTab = tabFromHash();
const walkthroughStep = ref(0);
const active = ref(
  tabs.some((t) => t.id === initialTab) ? initialTab : "overview",
);
const selectedId = ref(null),
  ticketDialog = ref(null);
const current = computed(() => tabs.find((t) => t.id === active.value));
const grafanaUrl = `${location.protocol}//${location.hostname}:3000`;
function navigate(id) {
  active.value = id;
  location.hash = id;
}
function select(id) {
  selectedId.value = id;
  navigate("tickets");
}
async function created(id) {
  await refresh();
  select(id);
}
watch(readPath, refresh);
window.addEventListener("hashchange", () => {
  const id = tabFromHash();
  if (tabs.some((t) => t.id === id)) {
    active.value = id;
  }
});
</script>
<template>
  <div class="app-shell">
    <aside class="sidebar">
      <a class="brand" href="#overview" @click="navigate('overview')"
        ><span class="brand-icon">▱</span
        ><span>Support Lab<small>ORACLE AI DATABASE</small></span></a
      >
      <label class="mobile-nav" for="workspace-view">Workspace
        <select id="workspace-view" :value="active" @change="navigate($event.target.value)">
          <option v-for="tab in tabs" :key="tab.id" :value="tab.id">{{ tab.title }}</option>
        </select>
      </label>
      <div class="nav-label">WORKSPACE</div>
      <nav aria-label="Main navigation">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          :class="{ active: active === tab.id }"
          :aria-current="active === tab.id ? 'page' : undefined"
          @click="navigate(tab.id)"
        >
          <span class="nav-icon" aria-hidden="true">{{ tab.icon }}</span
          ><span>{{ tab.title }}</span
          ><span v-if="tab.id === 'review' && ready.length" class="nav-count">{{
            ready.length
          }}</span
          ><span
            v-if="tab.id === 'failures' && failures.length"
            class="nav-count warning"
            >{{ failures.length }}</span
          >
        </button>
      </nav>
      <div class="sidebar-bottom">
        <a :href="grafanaUrl" target="_blank" rel="noopener"
          ><span>⌁</span> Open Grafana <span>↗</span></a
        >
        <div class="local-note">
          <span class="live-dot"></span
          ><span
            >Local development lab<small
              >Human decisions. Durable events.</small
            ></span
          >
        </div>
      </div>
    </aside>
    <main>
      <header class="topbar">
        <div class="breadcrumb">
          Customer support <span>/</span> {{ current.title }}
        </div>
        <div class="connection" :class="{ offline: error || !snapshot }">
          <span class="live-dot"></span
          >{{
            error
              ? "Connection issue"
              : snapshot
                ? "API connected"
                : "Connecting…"
          }}
        </div>
      </header>
      <div class="page-content">
        <div class="page-heading">
          <div>
            <h1>{{ current.title }}</h1>
            <p>{{ current.subtitle }}</p>
          </div>
          <button
            class="button primary"
            :disabled="!snapshot || !!error"
            @click="ticketDialog.open()"
          >
            <span>＋</span> New ticket
          </button>
        </div>
        <div class="toolbar">
          <div class="refresh-controls">
            <label class="checkbox-label"
              ><input v-model="autoRefresh" type="checkbox" />Live · 5s</label
            ><button class="text-button" :disabled="loading" @click="refresh">
              {{ loading ? "Refreshing…" : "↻ Refresh" }}
            </button>
          </div>
        </div>
        <div v-if="error" class="alert error" role="alert">{{ error }}</div>
        <template v-if="snapshot || active === 'diagrams'">
          <ReadPathControl
            v-if="active === 'tickets' || active === 'review'"
            v-model="readPath"
            :actual-path="actualPath"
          />
          <OverviewPanel
            v-if="active === 'overview'"
            :tickets="tickets"
            :snapshot="snapshot"
            :failures="failures"
            :ready="ready"
            :actual-path="actualPath"
            :grafana-url="grafanaUrl"
            @navigate="navigate"
            @select="select"
          />
          <TicketWorkspace
            v-if="active === 'tickets' || active === 'review'"
            :key="active"
            :tickets="tickets"
            :snapshot="snapshot"
            :refreshed-at="refreshedAt"
            :review-mode="active === 'review'"
            :initial-id="active === 'tickets' ? selectedId : null"
            @updated="refresh"
          />
          <FailuresPanel
            v-if="active === 'failures'"
            :failures="failures"
            @updated="refresh"
            @select="select"
          />
          <LabWalkthrough
            v-if="active === 'walkthrough'"
            v-model:step="walkthroughStep"
            v-model:read-path="readPath"
            :snapshot="snapshot"
            :tickets="tickets"
            :failures="failures"
            :actual-path="actualPath"
            :grafana-url="grafanaUrl"
            :refreshed-at="refreshedAt"
            @updated="refresh"
          />
          <DiagramsPanel v-if="active === 'diagrams'" />
          <KeepAlive>
            <SampleDataPanel
              v-if="active === 'samples'"
              :snapshot="snapshot"
              @updated="refresh"
              @select="select"
            />
          </KeepAlive>
        </template>
        <div v-else class="panel empty">
          <h2>
            {{
              error ? "The lab API is unavailable." : "Connecting to the lab…"
            }}
          </h2>
          <p>
            Start the Spring application on port 9001, then refresh this
            workspace.
          </p>
        </div>
        <footer>
          <span>Oracle AI Database · Customer Support Lab</span
          ><span>{{
            refreshedAt
              ? `Last refreshed ${refreshedAt.toLocaleTimeString()}`
              : "Waiting for first snapshot"
          }}</span>
        </footer>
      </div>
    </main>
    <NewTicketDialog
      ref="ticketDialog"
      @created="created"
    />
  </div>
</template>
