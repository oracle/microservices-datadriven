# Customer Support Lab UI

A small Vue 3 / Vite app for the local Spring Boot lab. No additional database,
UI service account, or frontend CDN is needed. Dependencies are bundled locally.

## Run

Start the lab services and Spring application as described in the
[lab README](../README.md). All features run by default:

```bash
mvn spring-boot:run
```

In another terminal, from this `ui` directory, with Node.js 22.12+ or 24+:

```bash
npm ci
npm run dev
```

Open **http://127.0.0.1:5173**. The Vite development server binds to loopback and
proxies `/api`, `/tickets`, and `/ticket-events` to `http://localhost:9001`.
If your backend uses another endpoint, set it when starting Vite:

```bash
LAB_API_URL=http://localhost:9011 npm run dev
```

All workflow tools are available without Spring profiles. Diagrams can be
browsed even when the backend is unavailable. This is the same
unauthenticated local demo API as the command-line walkthrough; the reviewer
field is a self-declared ID.

## Workspace tabs

- **Overview:** ticket state, summaries awaiting review, current failed worklist,
  review snapshot count, recent tickets, and the feedback flow.
- **Tickets:** search/filter requests; inspect summaries, policy matches, related
  tickets, accumulated feedback, and immutable review snapshots. Create a ticket
  from any tab. The optional failure-demo checkbox requires `demo-failures`.
- **Human Review:** starts with enriched tickets whose current summary has not
  been approved. Request revision with written feedback, or approve the current
  summary. A revision returns here after enrichment; an approved summary leaves
  the Needs review filter and the view advances to the next pending ticket.
  When none remain, the review workspace shows an all-caught-up summary.
  All tickets/history remain available through filters.
- **Failed Events:** failure metadata and replay action. Replay runs
  asynchronously and can call OCI again. Correct the cause before replaying.
- **Sample Data:** publish editable MFA, account-access, billing, and deliberate
  failure presets, or write a custom ticket. Inspect the JSON request preview
  and optionally supply a correlation UUID. The feedback mode lets you select
  an existing enriched ticket, load a feedback preset or write your own, and
  request regeneration through the normal review API. Replay mode uses the
  current failed worklist and preserves the original event type. Accepted
  requests are listed in the screen's in-memory session history; drafts/history
  survive tab navigation and reset on page reload.
- **Components:** database, TxEventQ/OKafka, OCI models, True Cache, blockchain,
  observability, row counts for all eight application tables, and policy corpus.
  The component inventory does not establish external service health.
- **Diagrams:** all 16 SVGs, category filters, presentation navigation, a gallery,
  full-size SVG links, and the preserved original scrolling gallery. Assets live
  in [`public/diagrams`](public/diagrams/README.md).

The workspace refreshes every five seconds while visible. You can pause live
refresh or refresh manually. List reads can use primary or True Cache and show
the actual `X-Read-Path`; ticket details and human review always request primary.
Cache results may lag. Connection errors retain the last snapshot with a stale
warning. Database counts are UI snapshots, not emitted telemetry.

Review submissions preserve the action UUID when retrying an unchanged request
after an uncertain response. Editing its fields starts a new action. Ticket
creation is not idempotent: check the list before retrying a lost response.

## Build

```bash
npm run build
npm run preview
```

The build writes `dist/`; preview serves it at **http://127.0.0.1:4173** with the
same backend proxy. Maven and Compose do not build or start the UI. Keep this
Vite server local; deployment/authentication are outside this lab.

## Source map

- `src/App.vue`: navigation and workspace shell.
- `src/composables/useLab.js`: refresh lifecycle and workspace snapshot.
- `src/api.js`: API requests, readable errors, and shared formatting.
- `src/components/`: individual views, details, review form, and history.
- `src/diagrams.js`: titles/descriptions and categories for the gallery.
- `src/samples.js`: editable scenarios based on walkthroughs, tests, and policies.
- `public/diagrams/`: canonical SVGs, standalone gallery, and source notes.
- `vite.config.js`: loopback listeners and development/preview proxies.

The backend adds one read-only `GET /api/lab` endpoint for configured
model/topic names, schema counts, policy data, and latest-review timestamps.
All ticket creation, assistance, review, and replay actions reuse existing APIs.
