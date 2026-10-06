# Customer Support Lab v2

One ticket tells the story: a Spring Boot API writes a ticket and publishes a
TxEventQ event in the same Oracle AI Database transaction; a consumer processes
it, records success or a durable failure, and lets an operator replay failed
work. True Cache serves freshness-tolerant ticket reads; the primary serves
fresh workflow reads. Optional chapters add Spring AI Oracle summaries/vector
retrieval and Grafana LGTM telemetry. See [spec-v2.md](spec-v2.md) for the
staged simplification plan.

This is a local teaching lab. Ticket and replay APIs have no authentication;
do not expose them outside a trusted development environment.

## Start here: ticket, failure, replay

Prerequisites: Docker Compose, JDK 21 or later, Maven (or `./mvnw`), SQLcl or
SQL*Plus, `curl`, and `jq`. OCI Generative AI credentials are **not** needed for
this path. Allow enough free Docker memory for the primary and True Cache
database instances. Work from the `customer-support-lab-v2` directory.

1. Start the full backing stack:

   ```bash
   export ORACLE_PWD='<local-admin-password>'
   docker compose up -d
   docker compose ps -a
   ```

   Wait for `oracle-free` and `true-cache` to be healthy and
   `true-cache-configure` to show `Exited (0)`. The helper's successful exit
   proves the primary-side cache service was registered. LGTM also starts.

2. Create a fresh lab schema and its objects:

   ```bash
   export APP_DB_USERNAME=LAB_USER
   export APP_DB_PASSWORD='<lab-user-password>'
   export ADMIN_DB_USERNAME=sys
   export ADMIN_DB_PASSWORD="$ORACLE_PWD"
   export ADMIN_DB_CONNECT=localhost:1522/FREEPDB1
   export ADMIN_DB_ROLE=sysdba
   ./scripts/setup-lab.sh
   ```

   This creates a fresh lab user, TxEventQ grants, tables, and three sample
   policies. It is for a clean schema; do not run it over populated lab data.

3. In the same terminal as step 2, start the application from Maven (or
   export `APP_DB_USERNAME` and `APP_DB_PASSWORD` again in a new terminal):

   ```bash
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=events,demo-failures
   ```

   The standard Compose connections are the defaults. The API listens on
   `localhost:9001`; Actuator listens on `localhost:9002`. Ticket GETs use
   True Cache by default; the walkthrough requests fresh primary reads when
   checking workflow status.

4. In another terminal, run the repeatable walkthrough:

   ```bash
   ./scripts/demo-failed-event-replay.sh
   ```

   Expect one ticket to move from `RECEIVED` to `FAILED` and, after replay,
   to `TRIAGED`. The replayed event makes one simulated transient attempt before
   succeeding when `TICKET_EVENT_MAX_ATTEMPTS` is at least 2. The script then
   proves **that same ticket** is readable from
   primary and True Cache. It exits unsuccessfully on cache fallback or if
   the ticket is still absent from cache after 30 seconds. Run it again to
   create another ticket without resetting the schema. The two printed
   workflow statuses may differ briefly while True Cache applies redo.
   If it says the ticket completed without the deliberate failure, restart
   Maven with `events,demo-failures` and run the script again.

   To inspect reads separately, run `./scripts/demo-true-cache-reads.sh`.

## Optional chapters

| Chapter | Start the app with | Observe |
| --- | --- | --- |
| AI assistance | `events,ai` | `./scripts/demo-ai-assistance.sh` prints a saved summary, model/prompt version, similar tickets, and policy matches. |
| Operations | `events,demo-failures,observability` | Run `./scripts/demo-failed-event-replay.sh`, then open Grafana at `http://localhost:3000` → Oracle AI Database → Customer Support Workflow. |

For the operations chapter, expect `failed` and `processed` in the event
outcomes panel and a final `TRIAGED` ticket count. The failed-worklist and
`FAILED` state gauges refresh every 10 seconds; the script may replay before
they capture the brief failure. The event counters record both outcomes.
The original deliberate failure is non-retryable; the replayed event makes
one transient attempt, so the retry panel should show a series once metrics
export catches up. With `TICKET_EVENT_MAX_ATTEMPTS=1`, the demo skips that
transient injection and still replays successfully. No data in the state panel
means metrics have not reached Grafana; it is not evidence of zero tickets.
The read-path panel should show `primary` and `true-cache` after the same
script; `primary-fallback` means the cache was not actually used.
To demonstrate fallback and recovery for an existing ticket, use the ID printed
by the replay script in place of `<ticket-id>`:

```bash
docker compose stop true-cache
curl -i 'http://localhost:9001/tickets/<ticket-id>?readPath=cache'
docker compose start --wait true-cache
docker compose up -d --no-deps --force-recreate true-cache-configure
docker compose ps -a true-cache-configure
```

The read during the outage remains HTTP 200 with
`X-Read-Path: primary-fallback`.
Wait for the helper to show `Exited (0)`, then rerun
`LAB_TICKET_ID=<ticket-id> ./scripts/demo-true-cache-reads.sh`. A restarted
ephemeral True Cache inherits the service definition but needs its
`FREEPDB1_TC` service started again; the helper now does that idempotently.
Open the separate Oracle UCP Metrics dashboard for primary-pool connection
activity. In Grafana's trace search, select service
`customer-support-lab-v2` and the last 15 minutes; inspect the ticket HTTP,
event-consumer, and JDBC spans. If Grafana is empty, check
`http://localhost:9002/actuator/metrics/support.ticket.events` first: local
measurements there point to an export/collector problem, while a missing
meter points to the app profile or event consumer. Run the replay script again
to generate another observation without resetting the schema.

Each standalone script can create a fresh ticket and can be rerun without
clearing data. The replay script reuses its ticket for the cache check.
For a blank-ticket reset between chapters, stop the app and use the deliberate
`db/truncate.sql` procedure below; the three seeded policies remain.

Stop the Maven app before changing profiles. Restart it with the new profile
list; use the same schema. AI requires a chat model and OCI authentication:

```bash
export OCI_COMPARTMENT_ID='<compartment-ocid>'
export OCI_AUTHENTICATION_TYPE=FILE
export OCI_CONFIG_FILE="$HOME/.oci/config"
export OCI_PROFILE=DEFAULT
export OCI_EMBEDDING_MODEL_ID=cohere.embed-english-v3.0
export OCI_CHAT_MODEL_ID='<available-chat-model-id>'
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,ai
```

On the first AI ticket, the processor embeds the small seeded policy corpus,
then stores a concise summary and scored references. Read them at
`GET /tickets/{id}/assistance`. Before enrichment it returns 404. Policies
are recommendations, not automatic decisions. The AI script exits successfully
only when that ticket has a nonempty saved summary, model/prompt metadata,
and at least one policy match. The first ticket may have no similar historical
tickets; run the script again to give the second ticket one to find. If it
reports `TRIAGED`, restart the app with `events,ai` and run it again. If it
reports `FAILED`, inspect the printed worklist event, correct the OCI/model
issue, and replay that event; replay may make another chargeable model call.
The schema expects 1024-dimensional embeddings and uses exact cosine scoring
for the small ticket and policy datasets. Use a fresh ticket dataset after
changing the embedding model. Policy indexing no longer makes a model call
during app startup. Model failures during ticket processing appear in the replayable
event worklist; missing OCI configuration may still prevent the AI profile
from starting.

## Configuration and API reference

The standard primary endpoint is `localhost:1522/FREEPDB1`; True Cache is
`localhost:1523/FREEPDB1_TC`. If those ports are occupied, set
`LAB_PRIMARY_PORT` and `LAB_TRUE_CACHE_PORT` before `docker compose up -d`,
then adjust `ADMIN_DB_CONNECT`, `JDBC_URL`, `OKAFKA_BOOTSTRAP_SERVERS`, and
`TRUE_CACHE_JDBC_URL` to match. `events` is the default app profile, but an
explicit profile list must include it. The app fails fast without
`APP_DB_USERNAME` and `APP_DB_PASSWORD`.

`scripts/setup-lab.sh` sends SQLcl/SQL*Plus connections over stdin so
passwords do not appear in the process listing. Its SQL-client substitution
accepts simple unquoted usernames and passwords made from letters, digits,
`. _ ! # % + -`; unsupported characters are rejected. Use
`./scripts/setup-lab.sh --dry-run` to validate inputs without connecting.
`LAB_BASE_URL` overrides `http://localhost:9001` for demo scripts. The
`[demo-fail-once]` prefix triggers the deliberate first failure; the same
ticket text without it processes normally. For a standalone cache check,
`LAB_TICKET_ID` can reuse an existing positive numeric ticket ID.

A prior local timing reached the first replay result in 104 seconds with
primary and LGTM only, cached images/dependencies, and operator pauses.
That is **not** a timing guarantee for the full True Cache stack. A separate
full-stack run verified two consecutive replay/cache walkthroughs without
resetting the schema; startup time still depends on host resources and cached
images.

The standard Compose startup includes True Cache. Check `docker compose ps -a`
and `docker compose logs true-cache-configure`; the helper must exit successfully
so the primary registers `FREEPDB1_TC`. It mounts the local Docker socket and
is not for shared hosts. Compose gives True Cache a stable `ORACLE_HOSTNAME`
and checks that its PDB accepts a query before running the registration helper.
`TRUE_CACHE_JDBC_URL` defaults to
`jdbc:oracle:thin:@//localhost:1523/FREEPDB1_TC`.
`TRUE_CACHE_DB_USERNAME` and `TRUE_CACHE_DB_PASSWORD` default to the app
credentials; `TRUE_CACHE_MAX_POOL_SIZE` defaults to 8 and
`TRUE_CACHE_DB_UNIQUE_NAME` to `TRUEFREE`. The reader checks the connected
database's `DB_UNIQUE_NAME` on each cache borrow before reporting
`X-Read-Path: true-cache`; a misconfigured primary endpoint yields
`primary-fallback` instead. This adds one SQL round trip to each cache read.

Only ticket list/detail GETs use the cache pool. They default to True Cache;
`?readPath=primary` forces a fresh primary read and `?readPath=cache` requests
a freshness-tolerant read. They select only core ticket fields, not embedding
or assistance references; use `/tickets/{id}/assistance` for recommendations.
`X-Read-Path` reports `primary`, `true-cache`, or `primary-fallback`, even for
404. A successful cache miss remains a 404, not a hidden primary read. Cache
connection failure falls back to primary. Writes, event processing, replay,
operator worklist, and assistance reads stay on primary. A single logical
driver-routed datasource is a future option, not the current implementation.
The cache script rejects `primary-fallback`; fallback is not proof of a cache
read.

```bash
ticket_id="$(curl -fsS -H 'Content-Type: application/json' \
  -d '{"title":"Lost MFA authenticator","description":"I lost my authenticator and cannot sign in. How can I recover access safely?"}' \
  http://localhost:9001/tickets | jq -er '.id')"
curl -i "http://localhost:9001/tickets/${ticket_id}?readPath=primary"
curl -fsS http://localhost:9001/ticket-events/failures
curl -X POST 'http://localhost:9001/ticket-events/failures/<event-uuid>/replay'
```

The versioned OSON event contains ticket ID, event type/ID, correlation ID,
optional causation ID, creation time, and trace context—never ticket text.
Java uses `UUID`, the database stores event IDs as `RAW(16)`, and HTTP/OSON
use canonical UUID strings. `X-Correlation-ID` accepts an optional UUID on
submission. The consumer retries transient failures up to three times with
exponential backoff (250 ms initial delay). Override with
`TICKET_EVENT_MAX_ATTEMPTS` and `TICKET_EVENT_RETRY_BACKOFF_MS`.

The failed-event table is an operator worklist, not a ticket-content review.
Replay marks the original event `REPLAYED` and atomically publishes a new
event whose causation ID is the original ID. A repeated replay request cannot
publish a second event. The processed-event table remains separate because it
is the small idempotency key set committed with enrichment; the failed-event
table holds the full replayable envelope and failure metadata. Merging them
would obscure these distinct transaction roles without improving this demo.
The consumer treats an event found in either table as already handled. A
redelivered original event cannot reopen a `REPLAYED` failure; failure records
are inserted once, not merged back to `FAILED`.
A missing or already replayed failure returns HTTP 404. An incomplete failure
envelope or a ticket no longer in `FAILED` returns HTTP 409. Neither case
publishes a new event.

The `observability` profile exports metrics and traces through OTLP HTTP to
`http://localhost:4318` by default, and adds JSON console logs and
ticket-state/worklist gauges. The core profile does not attempt OTLP export.
Oracle JDBC/UCP tracing and pool metrics are configured. Application logs are
**not** forwarded to LGTM without a separate appender; the configured OTLP log
endpoint alone is not proof of delivery. A local run verified a trace linking
HTTP ticket submission, event consumption, and an Oracle JDBC query. The
driver span comes from the primary JDBC datasource, not every
OKafka-internal database call. The small
dashboard covers emitted workflow metrics; it does not claim consumer lag or
OCI cost/rate-limit meters. Avoid customer text and IDs in metric labels.

For another database or collector, override `JDBC_URL`, `WALLET_DIR`,
`TNS_ALIAS`, `OKAFKA_SECURITY_PROTOCOL`, `OKAFKA_BOOTSTRAP_SERVERS`,
`OTEL_SERVICE_NAME`, `MANAGEMENT_OTLP_METRICS_EXPORT_*`,
`MANAGEMENT_OTLP_TRACING_*`, and `MANAGEMENT_SERVER_PORT` as appropriate. Keep
the JDBC trace-event-listener URL parameter on custom URLs. For OCI wallet
connections, set `OKAFKA_SECURITY_PROTOCOL=SSL`, `WALLET_DIR`, and
`TNS_ALIAS`; the local PLAINTEXT path obtains credentials from the app
environment through a temporary `ojdbc.properties` file.

## Reset and troubleshooting

`DELETE /tickets` is intentionally absent: an unauthenticated endpoint must
not truncate the whole lab. To intentionally clear **all** ticket, event,
assistance, and relation data in this disposable schema, stop the app and run
`db/truncate.sql` as the app user. It uses irreversible
`TRUNCATE` statements; inspect the target schema and retain anything needed
before running it. The policy corpus remains for the next walkthrough. To
stop infrastructure without removing volumes, run `docker compose down`.

For example, connect interactively with `sql /nolog`, then run
`connect <app-user>@localhost:1522/FREEPDB1` and `@db/truncate.sql` at the
SQL prompt; the client will request the password.

- Startup fails with missing credentials: export `APP_DB_USERNAME` and
  `APP_DB_PASSWORD` in the Maven terminal.
- Queue setup fails: verify the app user grants from `db/user.sql`, the primary
  service/port, and `OKAFKA_SECURITY_PROTOCOL=PLAINTEXT` for Compose. Only
  `PLAINTEXT` and `SSL` are supported; a typo now fails at startup instead of
  silently selecting PLAINTEXT.
- AI profile fails: check compartment, model availability, authentication,
  and 1024-dimensional embedding compatibility; the core path needs none of
  these credentials.
- No Grafana trace or metrics: check LGTM on port 4318 and the `MANAGEMENT_*`
  export overrides. A configured endpoint is not delivery evidence.
- Cache reads fail: check `true-cache-configure` exit status and primary-side
  service registration, then use `readPath=primary` while diagnosing. A cache
  miss immediately after a write can simply be redo lag. The cache's Docker
  health check waits for database readiness, not just an open listener. If it
  exits during `Create_truecache_instance`, inspect
  `docker inspect truecache --format '{{.State.OOMKilled}}'`; `true` means the
  Docker host needs more free memory before retrying the full topology.
