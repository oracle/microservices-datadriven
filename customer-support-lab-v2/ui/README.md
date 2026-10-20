# Customer Support Lab UI

A Vue 3 / Vite console for the local Spring Boot lab. Dependencies and diagram
assets are bundled locally; no frontend CDN or UI service account is needed.

## Run

Start Compose and Java using the [lab README](../README.md). All lab features
run by default. From this `ui` directory, use Node.js 22.12+:

```bash
npm ci
npm run dev
```

Open **http://127.0.0.1:5173**. Vite binds to loopback and proxies `/api`,
`/tickets`, and `/ticket-events` to `http://localhost:9001`. Override the backend
address when needed:

```bash
LAB_API_URL=http://localhost:9011 npm run dev
```

This is the lab's unauthenticated local demo API; reviewer IDs are self-declared.
Diagrams remain available when the backend is unavailable.

## Workspace

- **Overview:** ticket and review counts, failed worklist, recent tickets, and
  the feedback flow. Expand the component reference for services, configured
  TxEventQ topics, all eight application tables, and the policy corpus.
- **Lab Walkthrough:** seven chapters with animated diagrams and inline sample,
  ticket, review, recovery, and read-path tools. The component reference is also
  available on the first chapter.
- **Tickets:** search and filter requests, four per page. Inspect summaries and
  suggested resolutions; expand sources and generation details for policies,
  recorded related-ticket outcomes, similarity scores, and model metadata.
- **Human Review:** request a revision with feedback or approve saved assistance.
  After approval, the view advances to the next pending ticket. Use **All
  tickets** to revisit reviewed assistance and its immutable review history.
- **Failed Events:** inspect failures and replay work after correcting the cause.
  Replay runs asynchronously and can call OCI again.
- **Sample Data:** choose one editable synthetic scenario or write a custom
  request. Optional correlation IDs and the JSON request preview are expandable.
  Drafts and recent submissions survive tab navigation and reset on reload.
  Feedback and replay actions live in Human Review and Failed Events.
- **Diagrams:** category filters, presentation navigation, gallery layout, and
  full-size SVG links. The original standalone gallery remains available.

Create a ticket from any tab using **New ticket**. Its deliberate-failure
checkbox exercises the replay workflow. All views use larger text for
presenting; smaller screens use the **Workspace** selector for navigation.

The console refreshes every five seconds while visible. Pause live refresh or
refresh manually as needed. Ticket lists can use primary or True Cache and show
the actual `X-Read-Path`; ticket details and reviews always use primary. Database
counts are UI snapshots, not emitted telemetry or queue-depth measurements.

Review submissions preserve their action UUID when retrying an unchanged request
after an uncertain response. Editing the fields starts a new action. Ticket
creation is not idempotent: check the list before retrying a lost response.

## Build

```bash
npm run build
npm run preview
```

The build writes `dist/`; preview serves it at **http://127.0.0.1:4173** with the
same backend proxy. Maven and Compose do not build or start the UI.

## Source map

- `src/App.vue`: navigation and workspace shell.
- `src/composables/useLab.js`: refresh lifecycle and workspace snapshot.
- `src/api.js`: requests, readable errors, and shared formatting.
- `src/components/`: views, reusable workflow tools, and review history.
- `src/walkthrough.js`: chapter content and inline actions.
- `src/diagrams.js`: gallery titles, descriptions, and categories.
- `src/samples.js`: editable scenarios aligned with seeded policies and cases.
- [`public/diagrams`](public/diagrams/README.md): SVGs, standalone gallery, and source notes.
- `vite.config.js`: loopback listeners and development/preview proxies.

The read-only `GET /api/lab` endpoint supplies configured model/topic names,
table counts, policy data, and latest-review timestamps. Workflow actions reuse
the ticket, assistance, review, and replay APIs described in the lab README.
