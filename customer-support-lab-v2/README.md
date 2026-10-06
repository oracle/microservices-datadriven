# Customer Support Lab v2

Build a support-ticket workflow with Spring Boot and Oracle AI Database:
create a ticket, process its TxEventQ event, record a deliberate failure, replay
it, and read the same ticket through True Cache. Optional profiles add OCI
Generative AI assistance and metrics and traces in Grafana.

The application runs locally through Maven. Docker Compose supplies Oracle
Database Free, a separate True Cache instance, and Grafana LGTM. This is a
teaching lab: the ticket and replay APIs have no authentication, and the cache
registration helper mounts the local Docker socket. Use a trusted development
host.

## Prerequisites

- JDK 21 or later and Maven, or the included Maven wrapper.
- Docker with Docker Compose and enough available memory to run two Oracle
  database instances alongside LGTM.
- SQLcl (`sql`) or SQL*Plus (`sqlplus`) for schema setup.
- `curl` and `jq` for the walkthrough scripts.

Run the commands below from `customer-support-lab-v2`. The core walkthrough
requires no OCI credentials. The schema includes Oracle `VECTOR` columns even
when AI is disabled; use the supplied Oracle AI Database Free stack for this
local setup.

## Start the lab

### 1. Start the backing services

```bash
export ORACLE_PWD='Choose-Your-Admin-Password'
docker compose up -d
docker compose ps -a
```

Before creating the schema, wait for:

- `oracle-free` and `true-cache` to be healthy.
- `true-cache-password-volume-init` and `true-cache-configure` to exit with code 0.

The health checks execute database queries. The registration helper configures
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

### 2. Create a fresh schema

```bash
export APP_DB_USERNAME=LAB_USER
export APP_DB_PASSWORD='Choose-Your-Lab-Password'
export ADMIN_DB_USERNAME=sys
export ADMIN_DB_PASSWORD="$ORACLE_PWD"
export ADMIN_DB_CONNECT=localhost:1522/FREEPDB1
export ADMIN_DB_ROLE=sysdba
./scripts/setup-lab.sh
```

The script runs `db/user.sql` and `db/init.sql`: it creates the application
user, grants database and TxEventQ permissions, creates seven tables, and
seeds three support policies. Run it against a fresh schema, not an existing
populated one. The application creates or discovers the `ticket_event` topic
when it starts.

Setup passes credentials to the SQL client over stdin. Usernames must be
simple unquoted Oracle identifiers; passwords may contain letters, digits,
and `. _ ! # % + -`. The script rejects unsupported input. To check inputs
without connecting, run:

```bash
./scripts/setup-lab.sh --dry-run
```

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
export OCI_EMBEDDING_MODEL_ID=cohere.embed-english-v3.0
export OCI_CHAT_MODEL_ID='<available-chat-model-id>'
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
The small datasets use exact cosine search with a minimum score of 0.2.
The schema expects 1024-dimensional embeddings; use a fresh ticket dataset
when changing embedding models.

The script succeeds when the ticket is `ENRICHED` and its saved assistance
has a summary, model and prompt metadata, and at least one policy match. The
first ticket may have no similar tickets; rerun it to build history. Policy
matches are suggestions for human review.

A `TRIAGED` result means the app processed the ticket without AI. A `FAILED`
result directs you to the failed-event worklist. Correct the cause before
replaying; replay can make additional model calls. Database idempotency does
not guarantee exactly-once external OCI calls.

## Optional observability

Stop the app and restart with:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,demo-failures,observability
```

Run the replay walkthrough again, then open Grafana at
`http://localhost:3000`. Under **Oracle AI Database**, use **Customer Support
Workflow** for event outcomes, retries, enrichment steps, ticket states, and
read paths, and **Oracle UCP Metrics** for pool activity. To observe AI steps,
start with `events,ai,observability` and run the AI script.

The observability profile enables OTLP metrics and trace export, JSON console
logs, and database-backed state gauges. Metrics export every 5 seconds by
default; gauges refresh every 10 seconds. A quick replay may finish before a
gauge captures the brief `FAILED` state, while event counters retain both
outcomes. Search traces for service `customer-support-lab-v2`.

If Grafana is empty, check a local meter first:

```bash
curl -fsS http://localhost:9002/actuator/metrics/support.ticket.events
```

A local measurement helps distinguish export problems from absent event
activity. Oracle JDBC tracing is configured, but does not imply coverage of
every OKafka-internal call. Console logs are not automatically forwarded to
LGTM; an OTLP log endpoint alone does not establish log delivery.

## How the workflow is structured

1. Submission inserts a `RECEIVED` ticket and publishes an OSON work event in
   one producer transaction.
2. The consumer handles one event per transaction. It checks durable outcomes,
   marks the ticket `TRIAGED`, and invokes the core or AI processor.
3. Transient failures retry with savepoint rollback and exponential backoff.
   Exhausted or permanent failures produce a durable failure record and, when
   the ticket exists, a `FAILED` status.
4. Successful processing or the durable failure outcome commits with the
   TxEventQ acknowledgement. Redelivery of an event with an existing outcome
   skips processing.
5. Replay locks a failed record, marks it `REPLAYED`, resets its failed ticket
   to `RECEIVED`, and publishes a new event in one producer transaction. The
   new event's causation ID identifies the original failure.

The event carries a schema version, ticket ID, event type, UUIDs, timestamp,
and W3C trace context. Ticket text stays in the database. UUIDs use canonical
strings in HTTP/OSON and `RAW(16)` in database event tables.

Primary and cache reads have separate connection pools. Only ticket list and
detail GETs use True Cache; writes, processing, replay, worklist queries, and
assistance reads use primary. Each cache borrow verifies `DB_UNIQUE_NAME`
before reading. The ticket stores construct `SupportTicket` directly from
database rows.

### Project map

```text
customer-support-lab-v2/
├── pom.xml, mvnw                 Maven build and wrapper
├── docker-compose.yml           Primary, True Cache, registration helpers, LGTM
├── db/                          User grants, schema/seed data, reset and cleanup SQL
├── dashboards/                  Grafana provisioning and workflow/UCP dashboards
├── scripts/
│   ├── setup-lab.sh             Fresh-schema setup and input validation
│   ├── demo-common.sh           Sourced setup and ticket creation for HTTP demos
│   ├── demo-failed-event-replay.sh
│   ├── demo-true-cache-reads.sh
│   └── demo-ai-assistance.sh
├── src/main/java/com/oracle/demo/lab/
│   ├── Application.java         Boot entry point, executor, JDBC tracing import
│   ├── config/                  Required database credential validation
│   ├── web/                     Ticket, replay, and assistance endpoints
│   ├── events/                  OKafka setup, transactions, outcomes, retry, telemetry
│   ├── ticket/                  Ticket model, primary writes/reads, cache routing
│   └── ai/                      Summaries, vector retrieval, policy indexing, assistance
├── src/main/resources/          Base, AI, and observability configuration
├── src/test/                    Unit/profile tests, opt-in Oracle tests, startup scripts
└── spec-v2.md                   Lab design and evolution notes
```

`demo-common.sh` is sourced by the three walkthroughs; run their entry-point
scripts directly. The seven tables have distinct roles:

| Table | Stores |
| --- | --- |
| `support_ticket` | Ticket text, workflow state, optional embedding |
| `ticket_event_processed` | Completed-event idempotency keys |
| `failed_ticket_event` | Failure envelope, attempt metadata, replay state |
| `support_policy` | Seeded policy text and model-specific embeddings |
| `ticket_assistance` | Saved summary, model, prompt version, generation time |
| `related_ticket` | Scored links to similar tickets |
| `ticket_policy_match` | Scored links to policies |

## API reference

| Method and path | Behavior |
| --- | --- |
| `POST /tickets` | Accepts `title` and `description`; returns the created ticket. Optional `X-Correlation-ID` header accepts a UUID. |
| `GET /tickets` | Lists core ticket fields; accepts `readPath=primary` or `readPath=cache`. |
| `GET /tickets/{id}` | Reads one ticket; returns 404 when absent. Accepts the same read-path options. |
| `GET /ticket-events/failures` | Lists failed-event metadata, including replayability. |
| `POST /ticket-events/failures/{eventId}/replay` | Returns 202 with the new event; 404 for absent/already replayed failures; 409 for unsupported envelopes or a ticket no longer eligible for replay. |
| `GET /tickets/{id}/assistance` | Available with `ai`; returns saved assistance or 404 before it is available. |

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
| `APP_DB_USERNAME`, `APP_DB_PASSWORD` | Required in the application terminal; also used by schema setup. |
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
| `OTEL_SERVICE_NAME` | `customer-support-lab-v2`. |
| `MANAGEMENT_SERVER_PORT` | `9002`. |
| `MANAGEMENT_OTLP_METRICS_EXPORT_URL` | `http://localhost:4318/v1/metrics`. |
| `MANAGEMENT_OTLP_TRACING_ENDPOINT` | `http://localhost:4318/v1/traces`. |
| `MANAGEMENT_OTLP_METRICS_EXPORT_STEP`, `TICKET_STATE_REFRESH_MS` | `5s`, `10000` ms. |

Changing Compose ports does not change the Maven app's connection defaults.
Update `ADMIN_DB_CONNECT`, `JDBC_URL`, `OKAFKA_BOOTSTRAP_SERVERS`, and
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
schema prepared by `setup-lab.sh`, including its seeded policies:

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

## Reset, recovery, and troubleshooting

To stop services while keeping their containers and local database state:

```bash
docker compose stop
```

`docker compose down` removes containers; the current Compose setup does not
persist database data outside them. Treat the next startup as a fresh lab.

For a deliberate ticket-data reset, stop Maven, verify the schema, and run
`db/truncate.sql` as the app user. It irreversibly clears tickets, outcomes,
assistance, and scored links while retaining the policy corpus. There is no
`DELETE /tickets` reset endpoint. For example, open `sql /nolog`, then enter:

```text
connect LAB_USER@localhost:1522/FREEPDB1
@db/truncate.sql
```

The client prompts for the password. `db/cleanup.sql` is the separate
destructive schema-removal script; it is not needed to repeat a walkthrough.

To demonstrate cache fallback for an existing ticket, replace `<ticket-id>`
below with its ID:

```bash
docker compose stop true-cache
curl -i 'http://localhost:9001/tickets/<ticket-id>?readPath=cache'
docker compose start --wait true-cache
docker compose up -d --no-deps --force-recreate true-cache-configure
docker compose ps -a true-cache-configure
```

During the outage, an existing ticket can be served with
`X-Read-Path: primary-fallback`. After the helper exits with code 0, run
`LAB_TICKET_ID=<ticket-id> ./scripts/demo-true-cache-reads.sh` to prove recovery.

| Symptom | Check |
| --- | --- |
| Missing credentials at startup | Export `APP_DB_USERNAME` and `APP_DB_PASSWORD` in the Maven terminal. |
| Queue setup fails | Check `db/user.sql` grants, the primary service/port, and `OKAFKA_SECURITY_PROTOCOL=PLAINTEXT` for Compose. |
| Replay demo finishes without a deliberate failure | Restart with `events,demo-failures`. |
| AI demo reports `TRIAGED` | Restart with `events,ai`. |
| AI startup or enrichment fails | Check OCI credentials, compartment/model access, and 1024-dimensional embeddings; inspect failed-event metadata before replay. |
| Cache read falls back | Check database health, `true-cache-configure` logs/exit status, the cache URL, and expected `DB_UNIQUE_NAME`. |
| Cache returns 404 after a write | Allow for redo lag; the cache demo polls for visibility. |
| True Cache exits during creation | Inspect `docker inspect truecache --format '{{.State.OOMKilled}}'`; if true, free Docker memory before retrying. |
| Grafana has no measurements | Check the `observability` profile, local Actuator metrics, LGTM receiver, and export settings. |
