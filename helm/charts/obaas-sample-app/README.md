# OBaaS Sample Application Helm Chart

Deploy microservices to the Oracle Backend for Microservices and AI (OBaaS) platform with a single, framework-aware Helm chart. Whether you're building with Spring Boot or Helidon, this chart automatically wires up database connections, service discovery, health checks, and observability—all based on a single `framework` parameter.

## Quick Start

```yaml
# values.yaml
image:
  repository: us-phoenix-1.ocir.io/mytenancy/my-app
  tag: "1.0.0"

obaas:
  releaseName: "obaas"       # Your OBaaS platform release name
  framework: "SPRING_BOOT"   # or "HELIDON"

database:
  name: "myappdb"            # Database name for secret naming
```

```bash
helm install my-app ./obaas-sample-app -f values.yaml -n my-namespace
```

## Finding Your OBaaS Release Name

The `obaas.releaseName` must match the Helm release name used when the OBaaS platform was installed. To find it:

```bash
# List Helm releases in the OBaaS namespace
helm list -n <obaas-namespace>
```

Example output:
```
NAME    NAMESPACE   REVISION    STATUS      CHART         APP VERSION
obaas   citest      1           deployed    obaas-0.0.1   2.0.0-M5
```

The `NAME` column shows the release name (in this case, `obaas`). Use this value for `obaas.releaseName` in your values file.

If you don't know which namespace OBaaS was deployed to, search across all namespaces:

```bash
helm list -A | grep obaas
```

## Finding Your Database Name

The `database.name` is used to derive secret names. For Oracle Autonomous Database (ADB), find it using:

```bash
kubectl -n <obaas-namespace> get adb
```

Example output:
```
NAME          DISPLAY NAME   DB NAME    STATE       DEDICATED   OCPUS   STORAGE (TB)   WORKLOAD TYPE   CREATED
obaas-adb-s   CITESTDB       CITESTDB   AVAILABLE   false       0                      OLTP            2025-12-09 13:34:21 UTC
```

The `DB NAME` column (lowercase) is your `database.name`. In this example, use `citestdb`.

Verify the secrets exist with the expected naming pattern:

```bash
kubectl get secrets -n <obaas-namespace> | grep -E "db-authn|db-priv"
```

Expected output:
```
citestdb-db-priv-authn        Opaque   3
citestdb-obaas-db-authn       Opaque   3
```

## How It Works

The chart derives all platform resource names from two values:

| Value | Derives |
|-------|---------|
| `obaas.releaseName` | Eureka service, OTEL collector, OTMM config, wallet secret |
| `database.name` | Database auth secrets |

**Example with `obaas.releaseName: obaas` and `database.name: myappdb`:**

| Resource | Derived Name |
|----------|--------------|
| Eureka Service | `obaas-eureka` |
| OTEL Endpoint | `http://obaas-signoz-otel-collector:4318` |
| OTMM ConfigMap | `obaas-otmm-config` |
| Wallet Secret | `obaas-adb-tns-admin-1` |
| DB Auth Secret | `myappdb-obaas-db-authn` |
| Priv Auth Secret | `myappdb-db-priv-authn` |

## Required Values

### Minimal Configuration

```yaml
image:
  repository: ""    # (Required) Container image
  tag: ""           # (Required) Image tag

obaas:
  releaseName: ""   # (Required) OBaaS platform release name
  framework: ""     # (Required) SPRING_BOOT or HELIDON

database:
  name: ""          # (Required) Database name for secret naming
```

### Helidon Additional Requirements

Helidon applications require explicit datasource and service naming:

```yaml
helidon:
  datasource:
    name: "myds"              # Must match application.yaml
  otel:
    serviceName: "my-service" # OTEL service name
```

## Framework-Specific Configuration

### Spring Boot

The chart automatically configures:
- `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`
- `EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `SPRING_PROFILES_ACTIVE`
- Health probes at `/actuator/health/liveness` and `/actuator/health/readiness`
- Metrics at `/actuator/prometheus`

### Helidon

The chart automatically configures:
- `javax.sql.DataSource.<name>.*` properties
- `eureka.client.service-url.defaultZone`
- `OTEL_EXPORTER_OTLP_ENDPOINT` with `http/protobuf` protocol
- `server.port`, `server.host`
- Health probes at `/health/live` and `/health/ready`
- Metrics at `/metrics`

## Database Configuration

### Standard Authentication

Database secrets follow the naming pattern `{{ database.name }}-obaas-db-authn` with default keys:

| Key | Description |
|-----|-------------|
| `username` | Database username |
| `password` | Database password |
| `service` | TNS service name |

Create the secret:

```bash
kubectl create secret generic myappdb-obaas-db-authn \
  --from-literal=username=APP_USER \
  --from-literal=password='SecurePassword123!' \
  --from-literal=service=myatp_high \
  -n my-namespace
```

### Privileged Authentication (Liquibase)

For Spring Boot applications using Liquibase migrations, enable privileged auth:

```yaml
database:
  name: "myappdb"
  privAuthN:
    enabled: true
```

This injects `LIQUIBASE_DATASOURCE_*` environment variables from `{{ database.name }}-db-priv-authn`:

```bash
kubectl create secret generic myappdb-db-priv-authn \
  --from-literal=username=ADMIN \
  --from-literal=password='AdminPassword456!' \
  -n my-namespace
```

### Wallet Secret

The ADB wallet secret is derived from the OBaaS platform release: `{{ obaas.releaseName }}-adb-tns-admin-{{ revision }}`. This secret is created by the OBaaS platform chart and mounted at `/oracle/tnsadmin`.

## Feature Toggles

Enable or disable platform integrations:

```yaml
database:
  enabled: true      # Database configuration injection

eureka:
  enabled: true      # Eureka service discovery

otel:
  enabled: true      # OpenTelemetry tracing/metrics

otmm:
  enabled: false     # OTMM / MicroProfile LRA
```

## Optional Overrides

Override derived names only if your platform uses custom naming:

```yaml
database:
  authN:
    secretName: "custom-db-secret"    # Override derived name
    usernameKey: "user"               # Override default key
    passwordKey: "pass"
    serviceKey: "svc"
  privAuthN:
    secretName: "custom-priv-secret"
  walletSecret: "custom-wallet"

eureka:
  serviceName: "custom-eureka"
  port: 8761

otel:
  endpoint: "http://custom-collector:4318"

otmm:
  configMapName: "custom-otmm-config"
  urlKey: "EXTERNAL_ADDR"

springboot:
  profilesActive: "prod"
```

## Complete Example

### Spring Boot with Liquibase

```yaml
image:
  repository: us-phoenix-1.ocir.io/mytenancy/customer-service
  tag: "2.1.0"

imagePullSecrets:
  - name: ocir

fullnameOverride: "customer"

obaas:
  releaseName: "obaas"
  framework: "SPRING_BOOT"

database:
  name: "customerdb"
  privAuthN:
    enabled: true

replicaCount: 3

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Helidon

```yaml
image:
  repository: us-phoenix-1.ocir.io/mytenancy/inventory-service
  tag: "1.5.0"

imagePullSecrets:
  - name: ocir

fullnameOverride: "inventory"

obaas:
  releaseName: "obaas"
  framework: "HELIDON"

database:
  name: "inventorydb"

helidon:
  datasource:
    name: "inventory"
  otel:
    serviceName: "inventory-service"

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Troubleshooting

### Verify Secret Names

Check that derived secret names match actual secrets:

```bash
# List secrets
kubectl get secrets -n my-namespace | grep -E "authn|tns-admin"

# Check secret keys
kubectl get secret myappdb-obaas-db-authn -n my-namespace -o jsonpath='{.data}' | jq 'keys'
```

### Debug Template Rendering

```bash
# Render templates without installing
helm template my-app ./obaas-sample-app -f values.yaml --namespace my-namespace

# Dry-run against cluster
helm install my-app ./obaas-sample-app -f values.yaml -n my-namespace --dry-run=client
```

### Common Errors

**"secret not found"**: Verify `database.name` matches your secret naming convention.

**Helidon "DataSource not found"**: Ensure `helidon.datasource.name` matches your application's datasource bean name.

**OTEL metrics not appearing**: For Helidon, verify `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` is set.

**Health probe failures**: Check probe paths match your framework:
- Spring Boot: `/actuator/health/liveness`, `/actuator/health/readiness`
- Helidon: `/health/live`, `/health/ready`

## License

Copyright (c) 2024, 2025 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
