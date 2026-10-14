# Customer Support Lab v2

Build a support-ticket workflow with Spring Boot and Oracle AI Database:
create a ticket, process its TxEventQ event, record a deliberate failure, replay
it, and read the same ticket through True Cache. Optional profiles add OCI
Generative AI assistance and metrics and traces in Grafana.
An optional blockchain chapter records human reviews of saved AI summaries.
Regional placement is described as a deployment option; the Compose stack
remains a single local primary and its True Cache.

The application runs locally through Maven. Docker Compose supplies Oracle
Database Free, a separate True Cache instance, and Grafana LGTM. This is a
teaching lab: the ticket and replay APIs have no authentication, and the cache
registration helper mounts the local Docker socket. Use a trusted development
host.

TxEventQ is the queue inside the primary Oracle database. OKafka exposes it
through Kafka-style Java APIs; this lab does not run a separate Kafka broker.
The Spring Boot process serves HTTP requests and runs the background consumer.

```mermaid
flowchart LR
    Client[HTTP client] --> App[Spring Boot application]
    App -->|Ticket insert and event publish| Primary[(Oracle primary: tables and TxEventQ)]
    Primary -->|Work event| Consumer[Background consumer in the application]
    Consumer -->|Outcome and acknowledgement in one transaction| Primary
    Consumer -->|Optional embedding and summary calls| OCI[OCI Generative AI]
    Primary -->|Redo| Cache[(True Cache)]
    App -->|Default ticket GETs| Cache
    App -->|Explicit primary reads or cache unavailable| Primary
    App -->|Optional metrics and traces| LGTM[Grafana LGTM]
```

## Prerequisites

- JDK 21 or later and Maven, or the included Maven wrapper.
- Docker with Docker Compose 2.23.1 or later and enough available memory to run two Oracle
  database instances alongside LGTM.
- SQLcl (`sql`) or SQL*Plus (`sqlplus`) only for optional database checks.
- `curl` and `jq` for the walkthrough scripts.

Run the commands below from `customer-support-lab-v2`. The core walkthrough
requires no OCI credentials. The schema includes Oracle `VECTOR` columns even
when AI is disabled; use the supplied Oracle AI Database Free stack for this
local setup.

## Start the lab

### 1. Start the backing services

```bash
export ORACLE_PWD='Choose-Your-Admin-Password'
export APP_DB_USERNAME=LAB_USER
export APP_DB_PASSWORD='Choose-Your-Lab-Password'
docker compose up -d
docker compose ps -a
```

Before starting the Maven application, wait for:

- `oracle-free` and `true-cache` to be healthy.
- `true-cache-password-volume-init` and `true-cache-configure` to exit with code 0.

Compose supplies the application credentials through a small SQL config mounted
in the primary image's startup directory. It runs the self-contained
`db/init.sql` using the container's SQL*Plus client.
This creates the application user, grants database, TxEventQ, and blockchain
verification permissions, creates all eight tables, and seeds three support
policies. No host-side setup script or manual schema installation is needed.
The primary becomes healthy only after this setup succeeds and a
database query passes. Inspect setup failures with `docker compose logs oracle-free`.
The registration helper configures
`FREEPDB1_TC` on the primary and starts that service on True Cache. Inspect a
failed helper with `docker compose logs true-cache-configure`.

| Service | Local endpoint | Purpose |
| --- | --- | --- |
| Oracle primary | `localhost:1522/FREEPDB1` | Ticket writes, event transactions, fresh reads |
| True Cache | `localhost:1523/FREEPDB1_TC` | Freshness-tolerant ticket reads |
| Grafana | `http://localhost:3000` | Workflow and UCP dashboards, trace exploration |
| LGTM OTLP | `localhost:4317` / `localhost:4318` | gRPC / HTTP telemetry receivers |
| Application, started below | `http://localhost:9001` | Ticket and replay API |
| Actuator, started below | `http://localhost:9002/actuator` | Health and local metrics |

Database files and LGTM data have no dedicated persistent volumes in this
Compose file. The named volume holds the shared database password file;
it does not preserve ticket data when the database container is removed.

### 2. Confirm schema setup

Compose creates the user and tables for a fresh database; keep the same
`APP_DB_USERNAME` and `APP_DB_PASSWORD` exported for Maven. The SQL contains
plain creation statements, with no schema repair or restart checks. The lab
assumes a fresh Compose startup and supports restarting the application to
switch profiles while that database stays running.

For another fresh run, use `docker compose down` followed by `docker compose up -d`.
Database data is disposable and is not persisted across container recreation.
The application creates or discovers the `ticket_event` topic when it starts.

Use a simple unquoted Oracle username and a password containing letters, digits,
and `. _ ! # % + -`, matching the SQL*Plus substitution used by this lab.

### 3. Start the application

In the terminal with `APP_DB_USERNAME` and `APP_DB_PASSWORD` exported:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,demo-failures
```

You can replace `./mvnw` with `mvn`. In a new terminal, export the application
credentials again before starting Maven. Check health with:

```bash
curl -fsS http://localhost:9002/actuator/health
```

`events` is the default profile. Include it whenever you supply an explicit
profile list. `demo-failures` enables the deliberate failure and retry used
in the next step.

| Profile | Effect |
| --- | --- |
| `events` | Enables ticket submission/read APIs, the failure worklist and replay API, topic setup, and the background consumer. Default when no active profiles are supplied. |
| `demo-failures` | With `events`, injects deterministic failures for tickets whose title starts with `[demo-fail-once]`. |
| `ai` | Selects the OCI-backed processor and enables the saved-assistance API. Use with `events` to process tickets. |
| `observability` | Enables metrics/trace export and JSON console logs. Grafana calculates failure windows from emitted event counters. |
| `blockchain` | With `events`, enables approval-history POST/GET endpoints. Compose already creates its table; a new review requires saved AI assistance. |

### 4. Demonstrate failure, replay, and cache reads

In another terminal:

```bash
./scripts/demo-failed-event-replay.sh
```

The script creates a ticket with the `[demo-fail-once]` title prefix and waits
for `FAILED`. It replays the failed event, waits for `TRIAGED` in the core
profile, and checks that replaying the original again returns HTTP 404. With
at least two allowed attempts, the replay has one simulated transient failure
before succeeding.

It then checks that **the same ticket** is served by both primary and True
Cache. The cache check rejects `primary-fallback` and waits up to 30 polling
iterations for a cache miss to become visible. Workflow statuses may briefly
differ between primary and cache while redo is applied.

Rerun the script to create another ticket without resetting the schema.
If the deliberate failure does not occur, restart the app with
`events,demo-failures`.

For a separate read check, create a new ticket or reuse an existing one:

```bash
./scripts/demo-true-cache-reads.sh
LAB_TICKET_ID=42 ./scripts/demo-true-cache-reads.sh
```

All demo scripts accept `LAB_BASE_URL`, defaulting to `http://localhost:9001`.

## Optional AI assistance

Stop the Maven app, retain the schema, and configure OCI authentication and
models available to your compartment:

```bash
export OCI_COMPARTMENT_ID='<compartment-ocid>'
export OCI_AUTHENTICATION_TYPE=FILE
export OCI_CONFIG_FILE="$HOME/.oci/config"
export OCI_PROFILE=DEFAULT
export OCI_EMBEDDING_MODEL_ID=cohere.embed-v4.0
export OCI_CHAT_MODEL_ID=cohere.command-a-03-2025
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,ai
```

Then run:

```bash
./scripts/demo-ai-assistance.sh
```

AI processing embeds the ticket, searches related tickets and the seeded
policy corpus, generates a short summary, and persists the assistance and
`ENRICHED` status on the consumer's database connection. Policy embeddings
are created on first use and refreshed when the configured model changes.
Policy indexing commits on a separate primary connection, so it can remain
available even if the current ticket attempt rolls back. Ticket retrieval
returns up to five other tickets that already have embeddings; policy
retrieval returns up to three policies. The summary prompt contains only the
ticket title and description. Retrieved matches are saved alongside the
summary for human review; they are not supplied as context to the chat model.
The small datasets use exact cosine search with a minimum score of 0.2.
The default chat model is `cohere.command-a-03-2025` with temperature 0.2
and a 512-token output limit. Embeddings use `cohere.embed-v4.0`, requesting
1536 dimensions to match the schema and policy-index validation. Create a
fresh schema when changing vector dimensions; changing the model environment
variable does not migrate existing vector columns or stored embeddings.
Only policy embeddings are refreshed automatically after a model change;
existing ticket embeddings are not regenerated. For a model change, use a
fresh lab or deliberately rebuild the ticket embeddings to avoid comparing
vectors from different models, even when their dimensions match.

The script succeeds when the ticket is `ENRICHED` and its saved assistance
has a summary, model and prompt metadata, and at least one policy match. The
first ticket may have no similar tickets; rerun it to build history. Policy
matches are suggestions for human review.

A `TRIAGED` result means the app processed the ticket without AI. A `FAILED`
result directs you to the failed-event worklist. Correct the cause before
replaying; replay can make additional model calls. Database idempotency does
not guarantee exactly-once external OCI calls.

## Optional blockchain approval history

Record a human's `APPROVED` or `REJECTED` review of a saved AI summary. This
appends history without changing workflow status or executing customer
actions. `actorId` is a self-declared demo reviewer, not a verified identity;
the local APIs remain unauthenticated.

![Saved summary, human review, and blockchain approval history](visuals/blockchain-approval-history.svg)

Compose creates the blockchain table with the rest of the schema. Stop Maven
and restart with the OCI settings from the AI chapter:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,ai,blockchain
./scripts/demo-ai-assistance.sh
```

Use the `ENRICHED` ticket ID printed by the script. The following commands
use `uuidgen` to create an action UUID:

```bash
ticket_id=42 # Replace with your ENRICHED ticket ID.
action_id="$(uuidgen)"
payload="$(jq -cn --arg actionId "$action_id" \
  '{actionId: $actionId, decision: "APPROVED", actorId: "demo-reviewer", reason: "Reviewed manually"}')"
curl -fsS -H 'Content-Type: application/json' -d "$payload" \
  "http://localhost:9001/tickets/${ticket_id}/approvals" | jq

# Retry: returns the same record without appending again.
curl -fsS -H 'Content-Type: application/json' -d "$payload" \
  "http://localhost:9001/tickets/${ticket_id}/approvals" | jq
curl -fsS "http://localhost:9001/tickets/${ticket_id}/approvals" | jq
```

Each record preserves the summary text, SHA-256 digest of its exact UTF-8
bytes, model/prompt metadata, reviewer, decision, optional reason, and UTC
timestamp. The store locks the ticket, checks the action UUID, reads saved
`ENRICHED` assistance, and appends on one primary connection. It commits before
returning HTTP 200. Reusing the UUID with different request fields returns 409.
A correction uses a new UUID and appends another decision. The endpoint does
not generate a summary or publish a queue event.

The table uses Oracle V2 blockchain SHA2-512 chaining, separately from the
summary digest. Recent rows cannot be deleted during the 16-day row retention.
`NO DROP UNTIL 0 DAYS IDLE` permits deliberate full table removal for lab
cleanup; this is a demonstration retention policy. See the
[Oracle blockchain table documentation](https://docs.oracle.com/en/database/oracle/oracle-database/26/admin/managing-tables.html).

After committing a review, optionally open `sql /nolog` or `sqlplus /nolog`
and verify hashes as the application user (the client prompts for its password):

```text
connect LAB_USER@localhost:1522/FREEPDB1
@db/verify-approvals.sql
```

The script calls `DBMS_BLOCKCHAIN_TABLE.VERIFY_ROWS` and prints the verified
row count. It verifies row hashes, not reviewer signatures. Compose grants
the required package permission during bootstrap. See the
[verification API](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/dbms_blockchain_table.html).
To demonstrate modification protection, try updating your demo review and
observe Oracle reject the operation:

```sql
update ticket_approval_history set decision = 'REJECTED' where ticket_id = 42;
```

For a deliberate reset, `db/truncate.sql` drops the blockchain table before
clearing tickets, then recreates an empty ledger. Oracle prohibits truncating
a blockchain table, so the lab's zero-day table-retention policy makes this
explicit destructive reset possible. `db/cleanup.sql` removes the ledger
before the rest of the schema. Restarting Maven preserves approval history.

## Regional placement: deployment concept

The lab installs one local primary. A regional deployment could assign each
tenant to an owning region and keep its ticket text, embeddings, summaries,
event outcomes, and approval history there. Curated support policies can be
shared across regions. This diagram describes that topology; it does not
demonstrate geographic placement or automatic routing.

![Conceptual EU and US placement of ticket data with shared policies](visuals/regional-data-placement.svg)

One avenue is regional app/database deployments with tenant routing. Oracle
Globally Distributed AI Database is another, using placement and sharding
keys; it requires additional topology, schema, and routing work. See Oracle's
[data sovereignty use case](https://docs.oracle.com/en/database/oracle/oracle-database/26/shard/use-case-achieving-data-sovereignty.html).
Model endpoints, True Cache, backups, and telemetry need a corresponding
regional policy. No region field is added here to imply enforcement. Oracle
V2 blockchain tables cannot themselves be sharded; a combined sharded design
would need separately managed local approval ledgers and validation.

MicroTx remains a possible avenue when future workflows span independent
service or database transactions. The lab does not install MicroTx.

The standalone 800×600 SVGs inline source artwork from the social-icon-builder
skill: `ai.svg` and `security.svg` for approval history, and `pdb.svg` for
regional placement. The human-review illustration is original vector artwork.
Both passed strict SVG validation and were rendered and visually inspected.

## Optional observability

Stop the app and restart with:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,demo-failures,observability
```

Run the replay walkthrough again, then open Grafana at
`http://localhost:3000`. Under **Oracle AI Database**, use **Customer Support
Workflow** for recent failures, event outcomes, retries, processing latency, and
read paths, and **Oracle UCP Metrics** for pool activity. To observe AI steps,
start with `events,ai,observability` and run the AI script.

The observability profile enables OTLP metrics and trace export and JSON
console logs. Metrics export every 5 seconds by default. The application emits
event counters after commit; it does not query ticket counts for metrics.
Search traces for service `customer-support-lab-v2`.

The **Failed events** dashboard gauge shows failures in a rolling window,
defaulting to five minutes. It is green below five failures and red at five
or more. Select **Failure window** to change the window; edit the panel's red
threshold and maximum to change the limit. This changes the gauge's color;
it does not create a notification alert rule.

Grafana queries `sum(increase(support_ticket_events_total{outcome="failed"}[5m]))`
for the default window. A successful replay does not erase the original failure;
the gauge drops as failures leave the window. This is a sampled estimate,
not the current failed worklist size. Prometheus accounts for counter resets
on app restart and can return fractional increases. See
[Prometheus increase](https://prometheus.io/docs/prometheus/latest/querying/functions/#increase).
The failure counter is registered at startup to emit a zero baseline, but the
query needs at least two exported samples. Missing samples show **No data**,
rather than a synthetic healthy zero. Use `/ticket-events/failures` to inspect
the current worklist.

If Grafana is empty, check a local meter first:

```bash
curl -fsS http://localhost:9002/actuator/metrics/support.ticket.events
```

A local measurement helps distinguish export problems from absent event
activity. Oracle JDBC tracing is configured, but does not imply coverage of
every OKafka-internal call. Console logs are not automatically forwarded to
LGTM; an OTLP log endpoint alone does not establish log delivery.

## How the workflow is structured

### Submission and processing

`POST /tickets` returns HTTP 200 with the ticket in `RECEIVED` after the
producer transaction commits. It does not wait for processing. Poll
`GET /tickets/{id}?readPath=primary` for the current committed workflow state;
default cache reads can lag behind it.

1. Submission inserts a `RECEIVED` ticket and publishes an OSON work event in
   one producer transaction, using `TicketEventProducer` and the connection
   from `producer.getDBConnection()`.
2. The consumer handles one event per transaction. It checks durable outcomes,
   loads the ticket through the primary JDBC pool, marks it `TRIAGED` on
   `consumer.getDBConnection()`, and invokes the core or AI processor.
3. Transient failures retry with savepoint rollback and exponential backoff.
   Exhausted or permanent failures produce a durable failure record and, when
   the ticket exists, a `FAILED` status.
4. Successful processing or the durable failure outcome commits with the
   TxEventQ acknowledgement. Redelivery of an event with an existing outcome
   skips processing.
5. Replay locks a failed record, marks it `REPLAYED`, resets its failed ticket
   to `RECEIVED`, and publishes a new event in one producer transaction. The
   new event's causation ID identifies the original failure.

Without `ai`, `LogEventProcessor` logs the ticket and leaves its committed
status at `TRIAGED`. With `ai`, `GenAIEventProcessor` saves the embedding,
summary, and scored matches and commits `ENRICHED`. The intermediate
`TRIAGED` update belongs to that same transaction, so a separate HTTP read
normally sees `RECEIVED` until the AI transaction commits `ENRICHED` or
`FAILED`.

### Retry, failure, and replay

Retries happen within the consumer transaction. By default, retryable errors
allow three total attempts, with 250 ms and 500 ms waits between them. Each
failed attempt rolls back its database writes to a savepoint. If recording
the final outcome or committing fails, the whole transaction rolls back and
the queue message can be redelivered.

Failures are stored directly in the `failed_ticket_event` database worklist.
A recorded failure is acknowledged so the consumer can move on. Its
metadata includes the exception class and attempt count; inspect
application logs when investigating the cause. The failure API lists only
records still marked `FAILED`. Replay retains the original row as `REPLAYED`,
preserves the correlation ID, and gives the new event a new UUID. The ticket
must still be `FAILED` for replay to succeed. If the replayed event also
fails, it creates a new failure record that can be inspected and replayed.

Outcome checks deduplicate by event UUID, including failures already marked
`REPLAYED`. Replay intentionally creates a new event, so it is eligible for
processing. This transaction boundary protects database changes and queue
acknowledgements; OCI calls and policy indexing are outside its rollback scope.

The event carries a schema version, ticket ID, event type, UUIDs, timestamp,
and W3C trace context. Ticket text stays in the database. UUIDs use canonical
strings in HTTP/OSON and `RAW(16)` in database event tables.

Primary and cache reads have separate connection pools. Only ticket list and
detail GETs use True Cache; writes, processing, replay, worklist queries, and
assistance and approval-history reads use primary. Each cache borrow verifies `DB_UNIQUE_NAME`
before reading. Routing is explicit in `TicketReadRouter`, which chooses a
pool from the `readPath` query parameter; it does not use automatic JDBC
primary/cache switching. A missing row on a healthy cache is not a fallback
condition. Use `readPath=primary` when a read must reflect a completed write.

### Project map

```text
customer-support-lab-v2/
├── pom.xml, mvnw                 Maven build and wrapper
├── docker-compose.yml           Primary, True Cache, registration helpers, LGTM
├── db/                          User grants, schema/seed data, reset and cleanup SQL
├── dashboards/                  Grafana provisioning and workflow/UCP dashboards
├── visuals/                     Approval-history and conceptual regional-placement SVGs
├── scripts/
│   ├── demo-common.sh           Sourced setup and ticket creation for HTTP demos
│   ├── demo-failed-event-replay.sh
│   ├── demo-true-cache-reads.sh
│   └── demo-ai-assistance.sh
├── src/main/java/com/oracle/demo/lab/
│   ├── Application.java         Boot entry point, executor, JDBC tracing import
│   ├── web/                     Ticket, replay, and assistance endpoints
│   ├── model/                   Tickets, workflow status, event envelopes, failure metadata
│   ├── messaging/               OKafka setup, lifecycle, transactional publish/consume
│   ├── processing/              Core/AI processors and opt-in demo failures
│   ├── persistence/             Ticket storage, outcomes, UUID binding, cache routing
│   ├── observability/           Trace propagation and event-driven workflow metrics
│   └── ai/                      Summaries, vector retrieval, policy indexing, assistance
├── src/main/resources/          Base, AI, and observability configuration
├── src/test/                    Unit/profile tests, opt-in Oracle tests, startup scripts
└── spec-v2.md                   Lab design and evolution notes
```

`model` is shared by the HTTP endpoints, event processors, and AI retrieval.
`persistence.TicketStore` accepts the OKafka transaction connection for
workflow writes and uses Spring's primary `JdbcClient` for ordinary reads.
`persistence.TicketReadRouter` selects `TicketStore` or `TrueCacheTicketReader`
for ticket GETs. Tests mirror the production packages.

`demo-common.sh` is sourced by the three walkthroughs; run their entry-point
scripts directly. Compose creates all eight tables; the blockchain API remains
an optional profile:

| Table | Stores |
| --- | --- |
| `support_ticket` | Ticket text, workflow state, optional embedding |
| `ticket_event_processed` | Completed-event idempotency keys |
| `failed_ticket_event` | Failure envelope, attempt metadata, replay state |
| `support_policy` | Seeded policy text and model-specific embeddings |
| `ticket_assistance` | Saved summary, model, prompt version, generation time |
| `related_ticket` | Scored links to similar tickets |
| `ticket_policy_match` | Scored links to policies |
| `ticket_approval_history` | Blockchain history of human summary reviews, snapshots, and digests |

## API reference

| Method and path | Behavior |
| --- | --- |
| `POST /tickets` | Accepts `title` and `description`; returns the created ticket. Optional `X-Correlation-ID` header accepts a UUID. |
| `GET /tickets` | Lists core ticket fields; accepts `readPath=primary` or `readPath=cache`. |
| `GET /tickets/{id}` | Reads one ticket; returns 404 when absent. Accepts the same read-path options. |
| `GET /ticket-events/failures` | Lists failed-event metadata, including replayability. |
| `POST /ticket-events/failures/{eventId}/replay` | Returns 202 with the new event; 404 for absent/already replayed failures; 409 for unsupported envelopes or a ticket no longer eligible for replay. |
| `GET /tickets/{id}/assistance` | Available with `ai`; returns saved assistance or 404 before it is available. |
| `POST /tickets/{id}/approvals` | Available with `events,blockchain`; accepts `actionId` UUID, `decision`, `actorId`, and optional `reason`. Returns 200 with the review; 400 for invalid input, 404 for missing ticket, 409 for missing ENRICHED assistance or conflicting action UUID. |
| `GET /tickets/{id}/approvals` | Available with `events,blockchain`; reads primary history, returns an empty list before review, or 404 for missing ticket. |

Ticket GETs default to cache. Their `X-Read-Path` header reports `primary`,
`true-cache`, or `primary-fallback`, including on 404. A successful cache query
that finds no ticket remains a 404. Connection unavailability falls back to
primary; other query errors propagate. Invalid read-path values return 400.

```bash
ticket_id="$(curl -fsS -H 'Content-Type: application/json' \
  -d '{"title":"Login problem","description":"I cannot sign in."}' \
  http://localhost:9001/tickets | jq -er '.id')"
curl -i "http://localhost:9001/tickets/${ticket_id}?readPath=primary"
curl -fsS http://localhost:9001/ticket-events/failures
curl -i -X POST 'http://localhost:9001/ticket-events/failures/<event-uuid>/replay'
```

## Configuration reference

| Environment variable | Default / use |
| --- | --- |
| `APP_DB_USERNAME`, `APP_DB_PASSWORD` | Export before Compose and Maven; Compose defaults the username to `LAB_USER` and requires a password. |
| `ORACLE_PWD` | Compose admin password; set before startup (Compose otherwise uses `Welcome12345`). |
| `LAB_PRIMARY_PORT`, `LAB_TRUE_CACHE_PORT` | Compose host ports, `1522` and `1523`. |
| `JDBC_URL` | Primary JDBC URL, `localhost:1522/FREEPDB1`, with the JDBC trace listener parameter. |
| `OKAFKA_BOOTSTRAP_SERVERS` | `localhost:1522`. |
| `OKAFKA_SECURITY_PROTOCOL` | `PLAINTEXT`; only `PLAINTEXT` and `SSL` are accepted. |
| `WALLET_DIR`, `TNS_ALIAS` | `.` and `FREEPDB1`; for SSL, supply the wallet directory and service alias. |
| `TRUE_CACHE_JDBC_URL` | Cache JDBC URL, `localhost:1523/FREEPDB1_TC`, with the JDBC trace listener parameter. |
| `TRUE_CACHE_DB_USERNAME`, `TRUE_CACHE_DB_PASSWORD` | Application credentials. |
| `TRUE_CACHE_DB_UNIQUE_NAME`, `TRUE_CACHE_MAX_POOL_SIZE` | `TRUEFREE`, `8`. |
| `TICKET_EVENT_MAX_ATTEMPTS`, `TICKET_EVENT_RETRY_BACKOFF_MS` | `3` total attempts, `250` ms initial backoff. |
| `LAB_BASE_URL`, `LAB_TICKET_ID` | Demo API URL; optional existing ID for the cache demo. |
| `OCI_COMPARTMENT_ID` | Required with the `ai` profile. |
| `OCI_AUTHENTICATION_TYPE`, `OCI_CONFIG_FILE`, `OCI_PROFILE` | `FILE`, `${user.home}/.oci/config`, `DEFAULT`. |
| `OCI_CHAT_MODEL_ID`, `OCI_EMBEDDING_MODEL_ID` | `cohere.command-a-03-2025`, `cohere.embed-v4.0`; embeddings request 1536 dimensions. |
| `OTEL_SERVICE_NAME` | `customer-support-lab-v2`. |
| `MANAGEMENT_SERVER_PORT` | `9002`. |
| `MANAGEMENT_OTLP_METRICS_EXPORT_URL` | `http://localhost:4318/v1/metrics`. |
| `MANAGEMENT_OTLP_TRACING_ENDPOINT` | `http://localhost:4318/v1/traces`. |
| `MANAGEMENT_OTLP_METRICS_EXPORT_STEP` | `5s`. |

Changing Compose ports does not change the Maven app's connection defaults.
Update `JDBC_URL`, `OKAFKA_BOOTSTRAP_SERVERS`, and
`TRUE_CACHE_JDBC_URL` to match. Keep the
`oracle.jdbc.provider.traceEventListener=open-telemetry-trace-event-listener-provider`
query parameter on custom JDBC URLs when using JDBC tracing.

The local PLAINTEXT OKafka path writes app credentials to a temporary
`ojdbc.properties` file. Wallet-based SSL connections use `WALLET_DIR` and
`TNS_ALIAS`. Full property definitions are in
[`application.yaml`](src/main/resources/application.yaml),
[`application-ai.yaml`](src/main/resources/application-ai.yaml), and
[`application-observability.yaml`](src/main/resources/application-observability.yaml).

## Validation

Run the default test suite without starting the backing stack:

```bash
./mvnw test
```

The two Oracle persistence smoke tests are opt-in. They require a disposable
schema prepared automatically by Compose, including its seeded policies:

```bash
export LAB_DB_SMOKE_TEST=true
export LAB_SMOKE_JDBC_URL='jdbc:oracle:thin:@//localhost:1522/FREEPDB1'
export LAB_SMOKE_USERNAME="$APP_DB_USERNAME"
export LAB_SMOKE_PASSWORD="$APP_DB_PASSWORD"
./mvnw test -Dtest=TicketEventOutcomePersistenceSmokeTest,TicketAssistancePersistenceSmokeTest
```

These checks exercise persistence and rollback, not the complete OKafka,
True Cache, or OCI model flow. Use the walkthrough scripts against the running
app for those paths. The AI walkthrough requires actual OCI model access.

The separate blockchain smoke test uses the same Compose-prepared schema,
including its blockchain table and verification grant. It commits
one fixture ticket, assistance, and review, which remain after the test because
blockchain retention prevents ordinary cleanup. It checks deduplication,
conflicting actions, rolled-back appends, rejected updates/deletes, and chain
verification. Use a disposable lab with the same `LAB_SMOKE_*` exports above:

```bash
LAB_BLOCKCHAIN_SMOKE_TEST=true ./mvnw test -Dtest=TicketApprovalPersistenceSmokeTest
```

## Reset, recovery, and troubleshooting

To finish the lab, stop Maven and remove the backing containers:

```bash
docker compose down
```

`docker compose down` removes containers; the current Compose setup does not
persist database data outside them. Treat the next startup as a fresh lab.

For a deliberate ticket-data reset, stop Maven, verify the schema, and run
`db/truncate.sql` as the app user. It irreversibly clears tickets, outcomes,
assistance, scored links, and approval history while retaining the policy corpus. There is no
`DELETE /tickets` reset endpoint. For example, open `sql /nolog`, then enter:

```text
connect LAB_USER@localhost:1522/FREEPDB1
@db/truncate.sql
```

The client prompts for the password. `db/cleanup.sql` is the separate
destructive schema-removal script; it is not needed to repeat a walkthrough.

If the cache is unavailable, existing tickets can be served with
`X-Read-Path: primary-fallback`. For this lab, recreate the backing stack for
a fresh run instead of repairing or restarting the database containers.

| Symptom | Check |
| --- | --- |
| Missing credentials at startup | Export `APP_DB_USERNAME` and `APP_DB_PASSWORD` before Compose and in the Maven terminal. |
| Automatic schema setup fails | Inspect `docker compose logs oracle-free`; check credentials and use a fresh database container. |
| Queue setup fails | Check `db/init.sql` grants, the primary service/port, and `OKAFKA_SECURITY_PROTOCOL=PLAINTEXT` for Compose. |
| Replay demo finishes without a deliberate failure | Restart with `events,demo-failures`. |
| AI demo reports `TRIAGED` | Restart with `events,ai`. |
| AI startup or enrichment fails | Check OCI credentials, compartment/model access, and 1536-dimensional embeddings; inspect failed-event metadata before replay. |
| Cache read falls back | Check database health, `true-cache-configure` logs/exit status, the cache URL, and expected `DB_UNIQUE_NAME`. |
| Cache returns 404 after a write | Allow for redo lag; the cache demo polls for visibility. |
| True Cache exits during creation | Inspect `docker inspect truecache --format '{{.State.OOMKilled}}'`; if true, free Docker memory before retrying. |
| Grafana has no measurements | Check the `observability` profile, local Actuator metrics, LGTM receiver, and export settings. |
