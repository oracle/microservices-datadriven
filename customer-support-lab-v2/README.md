# Customer Support App

Demonstrates database Relational, JSON, Vector, and Eventing features in a progressive model using Spring Boot profiles to enable/disable certain features.

1. [Sample ticket requests](./ticket_requests.md)

## Environment variables

Before running the application, run the `user.sql` script on your database and configure the following environment variables:

```bash
APP_DB_USERNAME=<app schema username>
APP_DB_PASSWORD=<app schema password>
JDBC_URL=jdbc:oracle:thin:@<my TNS alias>?TNS_ADMIN=/path/to/wallet;
OCI_COMPARTMENT_ID=<embedding model compartment id>;
TNS_ALIAS=<tns alias>;
WALLET_DIR=</path/to/wallet>
OKAFKA_SECURITY_PROTOCOL=PLAINTEXT  # Set to PLAINTEXT for local/Docker; defaults to SSL (ADB wallet)
```

You can provision the schema with:

**Step 1 — create the app user** (run as a DBA):

```bash
export APP_DB_USERNAME=<app schema username>
export APP_DB_PASSWORD=<app schema password>
export ADMIN_DB_USERNAME=<admin username>
export ADMIN_DB_PASSWORD=<admin password>
export ADMIN_DB_CONNECT=<host:port/service>
./scripts/setup-lab-user.sh
```

**Step 2 — create the schema objects** (run as the app user):

```bash
sql ${APP_DB_USERNAME}/${APP_DB_PASSWORD}@<host:port/service> @src/test/resources/init.sql
```

`init.sql` creates the `support_ticket` table, the vector index, the `related_ticket` join table, and the `ticket_dv` JSON Relational Duality View. The app will fail with `ORA-04043` on the first request if this step is skipped.

The app now fails fast if `APP_DB_USERNAME` or `APP_DB_PASSWORD` is missing.

## Run local infrastructure with Docker Compose

`docker-compose.yml` starts the local backing services only; run the Spring
Boot application from Maven on the host. The default stack includes Oracle AI
Database Free and Grafana LGTM, which receives the application's OTLP metrics,
traces, and logs on port `4318`.

Set a database administrator password before starting the stack. The default is
provided only for local evaluation; choose a different password outside a
throwaway environment.

```bash
export ORACLE_PWD='<local-admin-password>'
docker compose up -d
docker compose ps
```

Wait until `oracle-free` is healthy before creating the application schema. The
primary database is available to host processes at `localhost:1522`.

```bash
export APP_DB_USERNAME=LAB_USER
export APP_DB_PASSWORD='<lab-user-password>'
export ADMIN_DB_USERNAME=sys
export ADMIN_DB_PASSWORD="$ORACLE_PWD"
export ADMIN_DB_CONNECT=localhost:1522/FREEPDB1
export ADMIN_DB_ROLE=sysdba
./scripts/setup-lab-user.sh

sql "${APP_DB_USERNAME}/${APP_DB_PASSWORD}@localhost:1522/FREEPDB1" \
  @src/test/resources/init.sql
```

Run the application from this directory. These values select the host-exposed
primary service and the local TxEventQ connection path:

```bash
export JDBC_URL='jdbc:oracle:thin:@//localhost:1522/FREEPDB1'
export OKAFKA_BOOTSTRAP_SERVERS=localhost:1522
export OKAFKA_SECURITY_PROTOCOL=PLAINTEXT
./mvnw spring-boot:run
```

The application API is available on `http://localhost:9001`, the management
endpoints on `http://localhost:9002/actuator`, and Grafana on
`http://localhost:3000`. The default `application.yaml` configuration exports
OTLP metrics, traces, and logs to `http://localhost:4318`; override the
`OTEL_SERVICE_NAME` or `MANAGEMENT_OTLP_*` variables when required.

### Optional Oracle True Cache

Start the True Cache profile when demonstrating read-only, freshness-tolerant
queries:

```bash
docker compose --profile true-cache up -d
docker compose ps
docker compose logs true-cache-configure
```

Wait for `true-cache-configure` to exit successfully. It performs the
primary-side registration that maps `FREEPDB1` to the True Cache service
`FREEPDB1_TC`. The cache service is then available to host processes at
`localhost:1523`:

```text
jdbc:oracle:thin:@//localhost:1523/FREEPDB1_TC
```

Use that service only for read-only work that can tolerate cache freshness lag;
ticket creation and workflow updates remain on the primary service. The
one-shot configuration helper mounts the local Docker socket, so the True Cache
profile is intended only for local development, not a shared Docker host.

Stop the stack with `docker compose down`. Add `--volumes` only when an
intentional reset of the shared True Cache password-file volume is required.

## App Profiles

Profiles are additive. The default is `rest`; add others to progressively unlock Oracle Database features. Activate additional profiles with:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=<profile1>,<profile2>
```

### rest

A basic REST controller to create and view SupportTickets.

```bash
./mvnw spring-boot:run
```

### events

Enables event-based ticket processing, replacing the basic REST controller.
- On ticket creation, an event is created and the ticket inserted into the database.
- A basic event consumer receives the ticket event and prints it to the console.

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events
```

### ai

Enables AI integration on ticket processing, using the `GenAIEventProcessor` class.
Each ticket processed will be embedded and linked to similar tickets using vector search.
Requires `events`.

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,ai
```

### json

Enables reads through a JSON Relational Duality View (`ticket_dv`). Requires `events`.
With `ai`, tickets are also written back through the duality view in a single round-trip
(embedding + related tickets + ticket data).

```bash
# Minimum — reads via ticket_dv, writes via direct SQL
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,json

# Full round-trip through the duality view (requires OCI credentials)
./mvnw spring-boot:run -Dspring-boot.run.profiles=events,ai,json
```

## API

The REST API is available in all profiles.

#### Create a ticket

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:9001/tickets" \
  -d '{"title": "My ticket", "description": "Need help with XYZ!"}'
```

#### Retrieve a ticket

```bash
curl -X GET "http://localhost:9001/tickets/{id}"
```

#### Retrieve all tickets

```bash
curl -X GET "http://localhost:9001/tickets"
```

## ORDS

ORDS (Oracle REST Data Services) must be installed and configured separately — it is not included in the `gvenzl/oracle-free` Docker image. It is pre-installed on OCI Autonomous Database. Run `src/test/resources/ords.sql` as the app user to enable the REST-enabled schema and view with authorization required.

For this lab, the ORDS AutoREST endpoint is accessed with database Basic authentication using the application schema credentials. Use HTTPS when passing database credentials. If you run standalone ORDS, make sure database/schema authentication is enabled for the ORDS pool before testing these `curl` commands.

When the ORDS schema and view are enabled, we can fetch ticket data using the ORDS REST API:

Unauthenticated requests should be rejected:

```bash
curl -i -X GET $ORDS_URL/support/ticket/
```

Authenticated requests use the application database credentials:

```bash
curl -X GET $ORDS_URL/support/ticket/ \
  -u "$APP_DB_USERNAME:$APP_DB_PASSWORD"
```

```bash
curl -X GET $ORDS_URL/support/ticket/ \
  -H "Content-Type: application/json"  \
  -u "$APP_DB_USERNAME:$APP_DB_PASSWORD"
```

## Cleanup between stages

The app includes a "Delete All" API that clears all app data, and can be run between showcase stages to clean-up data.

```bash
curl -X DELETE "http://localhost:9001/tickets"
```
