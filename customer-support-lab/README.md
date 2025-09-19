# Customer Support App

Demonstrates database Relational, JSON, Vector, and Eventing features in a progressive model using Spring Boot profiles to enable/disable certain features.

1. [Sample ticket requests](./ticket_requests.md)

## Environment variables

Before running the application, run the `user.sql` script on your database and configure the following environment variables:

```bash
JDBC_URL=jdbc:oracle:thin:@<my TNS alias>?TNS_ADMIN=/path/to/wallet;
OCI_COMPARTMENT_ID=<embedding model compartment id>;
TNS_ALIAS=<tns alias>;
WALLET_DIR=</path/to/wallet>
```

## App Profiles

### rest

A basic REST controller to create and view SupportTickets.

### events

Enables event-based ticket processing, replacing the basic REST controller.
- On ticket creation, an event is created and the ticket inserted into the database.
- A basic event consumer receives the ticket event and prints it to the console.

### ai

Enables AI integration on ticket processing, using the GenAIEventProcessor class.
Each ticket processed will be embedded, and linked to similar tickets using vector search.

### json

Enables saving tickets and related tickets as a single round-trip using a JSON Relational Duality View.

#### Create a ticket

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{"title": "My ticket", "description": "Need help with XYZ!"}'
```

#### Retrieve a ticket

```bash
curl -X GET "http://localhost:8080/tickets/{id}"
```

#### Retrieve all tickets
 ```bash
curl -X GET "http://localhost:8080/tickets"
```

## ORDS

When the ORDS schema and view are enabled, we can fetch ticket data use the ORDS REST API:

```bash
curl -X GET $ORDS_URL/support/ticket/ \
  -u 'testuser:testPWD12345'
```

```bash
curl -X GET $ORDS_URL/support/ticket/ \
  -H "Content-Type: application/json"  \
  -u 'testuser:testPWD12345'
```

## Cleanup between stages

The app includes a "Delete All" API that clears all app data, and can be run between showcase stages to clean-up data.

```bash
curl -X DELETE "http://localhost:8080/tickets"
```
