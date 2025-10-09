# OBaaS Sample Application Helm Chart

This Helm chart provides a **framework-agnostic** deployment template for microservices applications on the Oracle Backend for Microservices and AI (OBaaS) platform. It supports both **Spring Boot** and **Helidon** frameworks with automatic configuration of database integration, service discovery, and observability.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Guide](#configuration-guide)
  - [Spring Boot Deployment](#spring-boot-deployment)
  - [Helidon Deployment](#helidon-deployment)
- [Framework Comparison](#framework-comparison)
- [Observability and Metrics](#observability-and-metrics)
- [Secrets Management](#secrets-management)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## Overview

This Helm chart automatically configures framework-specific settings based on a single `framework` parameter. It eliminates the need for separate charts or complex conditional logic in your application code.

### Key Features

- **Single Framework Parameter**: Set `framework: SPRING_BOOT` or `framework: HELIDON` to automatically configure all framework-specific settings
- **Automatic Health Checks**: Framework-appropriate liveness and readiness probe endpoints
- **Built-in Observability**: OpenTelemetry integration with SigNoz for metrics, traces, and logs
- **Oracle Database Integration**: Autonomous Database (ADB) wallet mounting and connection configuration
- **Service Discovery**: Optional Eureka registration for microservices communication
- **Production Ready**: Includes resource management, autoscaling, and health probe configurations

### What Gets Auto-Configured

| Feature | Spring Boot | Helidon |
|---------|-------------|---------|
| **Health Endpoints** | `/actuator/health/liveness`<br/>`/actuator/health/readiness` | `/health/live`<br/>`/health/ready` |
| **Metrics Endpoint** | `/actuator/prometheus` | `/metrics` |
| **Database Config** | `SPRING_DATASOURCE_*` env vars | `javax.sql.DataSource.*` env vars |
| **Eureka Integration** | Spring Cloud Netflix | Helidon Eureka client |
| **OTEL Protocol** | HTTP/protobuf (port 4318) | HTTP/protobuf (port 4318) + auto-configure |
| **Service Name** | Auto from release name | Configurable via `otel.serviceName` |

## Architecture

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌───────────────┐         ┌──────────────────────┐        │
│  │  Your App Pod │         │  OBaaS Platform      │        │
│  ├───────────────┤         ├──────────────────────┤        │
│  │               │         │                      │        │
│  │  Spring Boot  │◄────────┤  Eureka (Discovery)  │        │
│  │     or        │         │                      │        │
│  │  Helidon MP   │◄────────┤  SigNoz (Observ.)    │        │
│  │               │         │                      │        │
│  │  ┌─────────┐  │         │  APISIX (Gateway)    │        │
│  │  │ Wallet  │  │         │                      │        │
│  │  │ Mount   │  │         │  Config Server       │        │
│  │  └─────────┘  │         │                      │        │
│  └───────┬───────┘         └──────────────────────┘        │
│          │                                                  │
│          ▼                                                  │
│  ┌───────────────┐                                         │
│  │   Oracle ADB  │                                         │
│  │  (Autonomous) │                                         │
│  └───────────────┘                                         │
└─────────────────────────────────────────────────────────────┘
```

### Template Structure

```
obaas-sample-app/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration (with TODOs)
├── templates/
│   ├── deployment.yaml     # Main deployment with framework conditionals
│   ├── service.yaml        # Kubernetes service
│   ├── serviceaccount.yaml # Service account (optional)
│   ├── ingress.yaml        # Ingress (optional)
│   ├── hpa.yaml            # Horizontal Pod Autoscaler (optional)
│   └── _helpers.tpl        # Template helpers
└── README.md               # This file
```

**Key Design Point**: The `deployment.yaml` template uses Helm conditionals (`{{- if eq .Values.obaas.framework "HELIDON" }}`) to render framework-specific environment variables, eliminating the need for multiple deployment templates.

## Prerequisites

### Required Infrastructure

1. **OBaaS Platform**: Installed in your Kubernetes cluster
   ```bash
   # Verify OBaaS installation
   kubectl get configmap obaas-config -n <obaas-namespace>
   kubectl get configmap obaas-observability-config -n <obaas-namespace>
   ```

2. **Kubernetes Cluster**: CNCF-compliant (v1.33.1+)
   ```bash
   kubectl version --short
   ```

3. **Helm**: Version 3.8+
   ```bash
   helm version
   ```

### Required Secrets

You'll need to create these secrets before deploying:

1. **Database Credentials Secret** - Contains Oracle DB connection info
2. **ADB Wallet Secret** - Contains Autonomous Database wallet files
3. **Image Pull Secret** - For pulling from private container registries (optional)

See [Secrets Management](#secrets-management) section for creation commands.

## Quick Start

### 1. Prepare Your Application

**For Spring Boot:**
- Add Spring Boot Actuator for health checks
- Add Spring Cloud Eureka Client for service discovery (optional)
- Add OpenTelemetry instrumentation for observability

**For Helidon:**
- Add Helidon Health for health checks
- Configure datasource name in `microprofile-config.properties`
- Add Helidon Eureka integration for service discovery (optional)
- Ensure OTEL service name matches in application config

### 2. Create Required Secrets

```bash
# Database credentials
kubectl create secret generic my-app-db-secret \
  --from-literal=db.username=YOUR_USER \
  --from-literal=db.password=YOUR_PASSWORD \
  --from-literal=db.service=myatp_high \
  -n your-namespace

# ADB wallet (download from OCI Console first)
unzip Wallet_MyATP.zip -d /tmp/wallet/
kubectl create secret generic my-app-adb-wallet \
  --from-file=/tmp/wallet/ \
  -n your-namespace

# Image pull secret (for OCI Registry)
kubectl create secret docker-registry ocir \
  --docker-server=us-phoenix-1.ocir.io \
  --docker-username='tenancy/username' \
  --docker-password='auth-token' \
  -n your-namespace
```

### 3. Configure values.yaml

Create a custom values file for your application:

**values-customer.yaml** (Helidon example):
```yaml
image:
  repository: "us-ashburn-1.ocir.io/mytenancy/customer-helidon"
  tag: "1.0.0"

imagePullSecrets:
  - name: ocir

fullnameOverride: "customer"  # Simplified deployment name

obaas:
  namespace: obaas-dev  # Your OBaaS installation namespace
  framework: HELIDON

  database:
    credentialsSecret: customer-db-secret
    walletSecret: dev-adb-wallet

  helidon:
    enabled: true
    datasource:
      name: "customer"  # Must match your application.yaml
    otel:
      serviceName: "customer"  # Must match microprofile-config.properties

  eureka:
    enabled: true

  otel:
    enabled: true
```

### 4. Deploy

```bash
helm install customer ./obaas-sample-app \
  -f values-customer.yaml \
  -n your-namespace \
  --create-namespace
```

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -n your-namespace

# Check logs
kubectl logs -f deployment/customer -n your-namespace

# Test health endpoint (port-forward first)
kubectl port-forward deployment/customer 8080:8080 -n your-namespace
curl http://localhost:8080/health/live  # Helidon
# or
curl http://localhost:8080/actuator/health/liveness  # Spring Boot
```

## Configuration Guide

### Spring Boot Deployment

#### Required Configuration

```yaml
obaas:
  namespace: obaas-cdd              # Your OBaaS namespace
  framework: SPRING_BOOT            # Framework selection

  database:
    credentialsSecret: app-db-secret
    walletSecret: app-adb-wallet

  springboot:
    enabled: true                   # Enable Spring Boot features

  eureka:
    enabled: true                   # Service discovery

  otel:
    enabled: true                   # Observability
```

#### What Gets Configured Automatically

**Environment Variables:**
```yaml
SPRING_DATASOURCE_URL: "jdbc:oracle:thin:@${DB_SERVICE}?TNS_ADMIN=/oracle/tnsadmin"
SPRING_DATASOURCE_USERNAME: <from secret>
SPRING_DATASOURCE_PASSWORD: <from secret>
SPRING_PROFILES_ACTIVE: <from obaas-config>
SPRING_CONFIG_LABEL: <from obaas-config>
EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: <from obaas-config>
EUREKA_INSTANCE_HOSTNAME: "<app-name>-<namespace>"
OTEL_EXPORTER_OTLP_ENDPOINT: <from obaas-observability-config>
```

**Health Probes:**
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

**Metrics Scraping:**
```yaml
podAnnotations:
  signoz.io/path: "/actuator/prometheus"
  signoz.io/port: "8080"
  signoz.io/scrape: "true"
```

#### Application Requirements

**pom.xml dependencies:**
```xml
<!-- Health checks -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<!-- Service discovery -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>

<!-- Metrics export (optional, for Prometheus format) -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

**application.properties:**
```properties
# Health endpoints
management.endpoints.web.exposure.include=health,prometheus,info,metrics
management.endpoint.health.probes.enabled=true
management.health.livenessState.enabled=true
management.health.readinessState.enabled=true

# Database (will be overridden by environment variables)
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver

# Eureka (will be overridden by environment variables)
eureka.client.enabled=true
```

### Helidon Deployment

#### Required Configuration

```yaml
obaas:
  namespace: obaas-cdd              # Your OBaaS namespace
  framework: HELIDON                # Framework selection

  database:
    credentialsSecret: app-db-secret
    walletSecret: app-adb-wallet

  helidon:
    enabled: true                   # Enable Helidon features

    datasource:
      name: "customer"              # CRITICAL: Must match application config

    hibernate:
      hbm2ddl_auto: create          # create, update, validate, none
      show_sql: true                # Set false in production
      format_sql: true

    server:
      host: "0.0.0.0"

    metrics:
      rest_request_enabled: false   # Enable REST request metrics

    otel:
      serviceName: "customer"       # CRITICAL: Must match microprofile-config.properties

    app:
      # Add custom properties here
      greeting: "Hello"

  eureka:
    enabled: true                   # Service discovery

  otel:
    enabled: true                   # Observability
```

#### What Gets Configured Automatically

**Environment Variables:**
```yaml
# Database configuration (note the datasource name substitution)
javax.sql.DataSource.customer.connectionFactoryClassName: "oracle.jdbc.pool.OracleDataSource"
javax.sql.DataSource.customer.URL: "jdbc:oracle:thin:@${DB_SERVICE}?TNS_ADMIN=/oracle/tnsadmin"
javax.sql.DataSource.customer.user: <from secret>
javax.sql.DataSource.customer.password: <from secret>

# Hibernate settings
hibernate.hbm2ddl.auto: "create"
hibernate.show_sql: "true"
hibernate.format_sql: "true"

# Server configuration
server.port: "8080"
server.host: "0.0.0.0"

# Metrics
metrics.rest-request.enabled: "false"

# Eureka
eureka.client.service-url.defaultZone: "http://eureka-0.eureka.obaas-cdd.svc.cluster.local:8761/eureka"
eureka.instance.hostname: "<app-name>-<namespace>"
eureka.instance.preferIpAddress: "true"

# OpenTelemetry (CRITICAL for metrics export)
OTEL_EXPORTER_OTLP_ENDPOINT: <from obaas-observability-config>
OTEL_EXPORTER_OTLP_PROTOCOL: "http/protobuf"  # Critical: Uses HTTP not gRPC
OTEL_SERVICE_NAME: "customer"
OTEL_SDK_DISABLED: "false"
OTEL_METRICS_EXPORTER: "otlp"
JAVA_TOOL_OPTIONS: "-Dotel.java.global-autoconfigure.enabled=true"
```

**Health Probes:**
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

**Metrics Scraping:**
```yaml
podAnnotations:
  signoz.io/path: "/metrics"
  signoz.io/port: "8080"
  signoz.io/scrape: "true"
```

#### Application Requirements

**pom.xml dependencies:**
```xml
<!-- Health checks -->
<dependency>
    <groupId>io.helidon.microprofile.health</groupId>
    <artifactId>helidon-microprofile-health</artifactId>
</dependency>

<!-- Database connection pooling -->
<dependency>
    <groupId>io.helidon.integrations.cdi</groupId>
    <artifactId>helidon-integrations-cdi-hikaricp</artifactId>
</dependency>

<!-- JPA/Hibernate -->
<dependency>
    <groupId>io.helidon.integrations.cdi</groupId>
    <artifactId>helidon-integrations-cdi-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.hibernate.orm</groupId>
    <artifactId>hibernate-core</artifactId>
</dependency>

<!-- Oracle JDBC -->
<dependency>
    <groupId>com.oracle.database.jdbc</groupId>
    <artifactId>ojdbc11</artifactId>
</dependency>

<!-- Service discovery (optional) -->
<dependency>
    <groupId>io.helidon.microprofile.cdi</groupId>
    <artifactId>helidon-microprofile-cdi</artifactId>
</dependency>

<!-- Metrics -->
<dependency>
    <groupId>io.helidon.microprofile.metrics</groupId>
    <artifactId>helidon-microprofile-metrics</artifactId>
</dependency>

<!-- OpenTelemetry -->
<dependency>
    <groupId>io.helidon.tracing</groupId>
    <artifactId>helidon-tracing</artifactId>
</dependency>
```

**microprofile-config.properties:**
```properties
# Datasource name (MUST match values.yaml)
javax.sql.DataSource.customer.connectionFactoryClassName=oracle.jdbc.pool.OracleDataSource

# Server configuration
server.port=8080
server.host=0.0.0.0

# Health checks
health.enabled=true

# Metrics
metrics.enabled=true
metrics.rest-request.enabled=true

# OpenTelemetry (MUST match values.yaml)
otel.sdk.disabled=false
otel.service.name=customer
otel.metrics.exporter=otlp
```

#### CRITICAL Configuration Matching

**These values MUST match between values.yaml and your application:**

1. **Datasource Name**
   - `values.yaml`: `obaas.helidon.datasource.name: "customer"`
   - `microprofile-config.properties`: `javax.sql.DataSource.customer.*`

2. **OTEL Service Name**
   - `values.yaml`: `obaas.helidon.otel.serviceName: "customer"`
   - `microprofile-config.properties`: `otel.service.name=customer`

**Mismatch Symptoms:**
- Datasource name mismatch → "DataSource not found" error at runtime
- OTEL service name mismatch → Metrics appear under wrong service in SigNoz

## Framework Comparison

### When to Use Each Framework

**Use Spring Boot when:**
- You need a large ecosystem of libraries and integrations
- Team has Spring Boot expertise
- Building enterprise applications with complex business logic
- Need mature tooling and IDE support
- Want convention-over-configuration approach

**Use Helidon when:**
- You need lightweight microservices with smaller memory footprint
- Performance and startup time are critical
- Want MicroProfile standard compliance
- Building cloud-native, containerized applications
- Prefer explicit configuration over auto-configuration

### Resource Comparison

| Metric | Spring Boot | Helidon |
|--------|-------------|---------|
| **Startup Time** | ~8-15 seconds | ~3-8 seconds |
| **Memory (Idle)** | ~350-500 MB | ~200-350 MB |
| **Memory (Load)** | ~600-1000 MB | ~400-700 MB |
| **JAR Size** | ~50-80 MB | ~30-50 MB |
| **CPU (Idle)** | 50-100m | 50-80m |
| **Native Image** | Partial support | Full GraalVM support |

### Recommended Resources

**Spring Boot:**
```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

**Helidon:**
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Observability and Metrics

### Overview

This chart integrates with SigNoz for comprehensive observability:

- **Metrics**: Exported via OpenTelemetry Protocol (OTLP) or Prometheus scraping
- **Traces**: Distributed tracing across microservices
- **Logs**: Centralized log collection and correlation

### Metrics Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────┐
│   Your App      │         │  SigNoz OTEL     │         │  ClickHouse │
│                 │─OTLP───▶│  Collector       │────────▶│  (Storage)  │
│  /metrics       │         │                  │         │             │
│  endpoint       │         │  Also scrapes    │         │             │
│                 │◄─scrape─│  Prometheus      │         │             │
└─────────────────┘         │  metrics         │         └─────────────┘
                            └──────────────────┘
                                     │
                                     ▼
                            ┌──────────────────┐
                            │   SigNoz UI      │
                            │  (Visualization) │
                            └──────────────────┘
```

### How Metrics Are Collected

**Spring Boot:**
1. Micrometer collects metrics internally
2. OTEL integration pushes via OTLP to SigNoz collector (port 4318)
3. SigNoz also scrapes `/actuator/prometheus` endpoint
4. Metrics appear under the service name (derived from Helm release name)

**Helidon:**
1. MicroProfile Metrics collects metrics
2. OTEL SDK (auto-configured) pushes via OTLP to SigNoz collector (port 4318)
3. SigNoz also scrapes `/metrics` endpoint
4. Metrics appear under configured service name (`otel.serviceName`)

**Key Difference**: Helidon requires explicit OTLP protocol configuration (`http/protobuf`) to avoid gRPC connection errors.

### Querying Metrics in SigNoz

#### Finding Your Service Metrics

Metrics are tagged with Kubernetes metadata. Use these filters:

**Filter by Pod Name:**
```
Metric: requests_count_total
WHERE: k8s_pod_name CONTAINS "customer"
```

**Filter by Namespace:**
```
Metric: memory_usedHeap_bytes
WHERE: k8s_namespace_name = "production" AND k8s_pod_name CONTAINS "customer"
```

**Common Filters:**
- `k8s_pod_name` - Pod name (includes release name)
- `k8s_namespace_name` - Kubernetes namespace
- `k8s_container_name` - Container name
- `service_name` - OTEL service name (Helidon) or "signoz-scraper" (for Prometheus metrics)

#### Available Metrics

**Helidon Metrics:**
- `requests_count_total` - Total HTTP requests
- `memory_usedHeap_bytes` - JVM heap memory usage
- `memory_committedHeap_bytes` - JVM committed memory
- `thread_count` - Current thread count
- `cpu_systemLoadAverage` - System load average
- `jvm_uptime_seconds` - Service uptime
- `gc_time_seconds_total` - Garbage collection time
- `gc_total` - GC count

**Spring Boot Metrics:**
- `http_server_requests_seconds` - HTTP request duration
- `jvm_memory_used_bytes` - JVM memory usage
- `jvm_gc_pause_seconds` - GC pause time
- `process_cpu_usage` - CPU usage percentage
- `tomcat_threads_current` - Active thread count (if using Tomcat)

#### Example Queries

**Request Rate (requests per second):**
```
Metric: requests_count_total
Aggregation: Rate
WHERE: k8s_pod_name CONTAINS "customer"
```

**Memory Usage Over Time:**
```
Metric: memory_usedHeap_bytes
Aggregation: Avg
WHERE: k8s_namespace_name = "production"
GROUP BY: k8s_pod_name
```

**Service Uptime:**
```
Metric: jvm_uptime_seconds
Aggregation: Last
WHERE: k8s_pod_name CONTAINS "customer"
```

### Enabling/Disabling Observability

**Disable all observability:**
```yaml
obaas:
  otel:
    enabled: false
```

**Disable only OTLP push (keep Prometheus scraping):**
```yaml
obaas:
  otel:
    enabled: false

podAnnotations:
  signoz.io/scrape: "true"  # Keep scraping enabled
  signoz.io/port: "8080"
  signoz.io/path: "/metrics"  # or /actuator/prometheus
```

### Troubleshooting Metrics

**Metrics not appearing in SigNoz:**

1. **Check OTEL environment variables:**
   ```bash
   kubectl exec deploy/customer -n your-ns -- env | grep OTEL
   ```
   Should show: `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`

2. **Check for export errors in logs:**
   ```bash
   kubectl logs deploy/customer -n your-ns | grep -i "failed to export"
   ```
   If you see gRPC errors, the protocol is not set correctly.

3. **Verify metrics endpoint is working:**
   ```bash
   kubectl port-forward deploy/customer 8080:8080 -n your-ns
   curl http://localhost:8080/metrics  # Helidon
   curl http://localhost:8080/actuator/prometheus  # Spring Boot
   ```

4. **Check pod annotations:**
   ```bash
   kubectl get pod -l app.kubernetes.io/instance=customer -o jsonpath='{.items[0].metadata.annotations}' | jq
   ```
   Should have `signoz.io/scrape: "true"`

**Helidon-specific**: If seeing "AutoConfiguredOpenTelemetrySdk found but automatic configuration is disabled":
- Verify `JAVA_TOOL_OPTIONS=-Dotel.java.global-autoconfigure.enabled=true` is set
- This is automatically configured when `obaas.otel.enabled=true`

## Secrets Management

### Database Credentials Secret

**Required Keys:**
- `db.username` - Database user
- `db.password` - Database password
- `db.service` - TNS service name from tnsnames.ora

**Creation:**
```bash
kubectl create secret generic my-app-db-secret \
  --from-literal=db.username=CUSTOMER_USER \
  --from-literal=db.password='MySecurePassword123!' \
  --from-literal=db.service=myatp_high \
  -n your-namespace
```

**Verification:**
```bash
kubectl get secret my-app-db-secret -n your-namespace -o jsonpath='{.data}' | jq 'keys'
# Should show: ["db.password", "db.service", "db.username"]
```

### ADB Wallet Secret

**Required Files** (from OCI Console download):
- `tnsnames.ora`, `sqlnet.ora`, `cwallet.sso`, `ewallet.p12`, `keystore.jks`, `truststore.jks`

**Creation:**
```bash
# Download wallet ZIP from OCI Console
# Unzip to temporary directory
unzip Wallet_MyATP.zip -d /tmp/wallet/

# Create secret from all files
kubectl create secret generic my-app-adb-wallet \
  --from-file=/tmp/wallet/ \
  -n your-namespace

# Clean up
rm -rf /tmp/wallet
```

**Verification:**
```bash
kubectl get secret my-app-adb-wallet -n your-namespace -o jsonpath='{.data}' | jq 'keys'
# Should show all wallet files
```

**How it's used:**
- Secret is mounted as volume at `/oracle/tnsadmin` in the container
- JDBC connection string includes `TNS_ADMIN=/oracle/tnsadmin`
- Oracle drivers automatically read wallet files from this location

### Image Pull Secret (OCI Registry)

**For OCI Registry (OCIR):**
```bash
kubectl create secret docker-registry ocir \
  --docker-server=us-phoenix-1.ocir.io \
  --docker-username='tenancy-namespace/oracleidentitycloudservice/user@example.com' \
  --docker-password='your-auth-token' \
  -n your-namespace
```

**Finding your values:**
1. **Region**: Your OCI region (e.g., `us-phoenix-1`, `us-ashburn-1`)
2. **Tenancy Namespace**: OCI Console → Administration → Tenancy Details → Object Storage Namespace
3. **Username**: Your OCI username (often starts with `oracleidentitycloudservice/`)
4. **Auth Token**: Generate at OCI Console → User Settings → Auth Tokens → Generate Token

**Configure in values.yaml:**
```yaml
imagePullSecrets:
  - name: ocir
```

## Troubleshooting

### Common Issues

#### 1. Pod in CrashLoopBackOff

**Symptom:** Pod keeps restarting

**Check logs:**
```bash
kubectl logs pod/customer-xxx -n your-namespace --previous
```

**Common causes:**

**Database connection error:**
```
ORA-01017: invalid username/password
TNS: could not resolve the connect identifier
```
- Verify `db.username`, `db.password`, `db.service` in credentials secret
- Check wallet secret contains all required files
- Verify `db.service` matches an entry in `tnsnames.ora`

**Datasource not found (Helidon):**
```
javax.sql.DataSource.customer not found
```
- Ensure `obaas.helidon.datasource.name` in values.yaml matches your `application.yaml`
- Check environment variables: `kubectl exec deploy/customer -- env | grep javax.sql.DataSource`

**Framework mismatch:**
```
attempt to set an empty or null database URL
```
- Likely deploying Helidon app with `framework: SPRING_BOOT` (or vice versa)
- Verify framework setting matches your application

#### 2. Health Probe Failures

**Symptom:** Pod shows "Unhealthy" or restarts frequently

**Test health endpoints:**
```bash
kubectl port-forward deploy/customer 8080:8080 -n your-namespace

# Helidon
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready

# Spring Boot
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness
```

**Fixes:**

**Slow startup:**
```yaml
livenessProbe:
  initialDelaySeconds: 60  # Increase from default 30
```

**Database dependency:**
```yaml
readinessProbe:
  initialDelaySeconds: 20  # Give DB time to connect
  failureThreshold: 5      # More tolerance
```

#### 3. Metrics Not Appearing

**See detailed troubleshooting in [Observability and Metrics](#troubleshooting-metrics) section above.**

Quick checklist:
- [ ] `obaas.otel.enabled: true`
- [ ] OTEL_EXPORTER_OTLP_PROTOCOL set to "http/protobuf" (Helidon)
- [ ] No "failed to export" errors in logs
- [ ] Pod has signoz.io annotations
- [ ] Metrics endpoint returns data
- [ ] For Helidon: service name matches in values.yaml and microprofile-config.properties

#### 4. Eureka Registration Failing

**Check Eureka environment variables:**
```bash
kubectl exec deploy/customer -n your-namespace -- env | grep -i eureka
```

**Verify OBaaS ConfigMap exists:**
```bash
kubectl get configmap obaas-config -n <obaas-namespace> -o yaml | grep eureka
```

**Spring Boot Eureka logs:**
```bash
kubectl logs deploy/customer -n your-namespace | grep -i eureka
```

Should see: "DiscoveryClient registering service" and "Registered instance"

#### 5. Image Pull Errors

**Symptom:** `ImagePullBackOff` or `ErrImagePull`

**Check events:**
```bash
kubectl describe pod customer-xxx -n your-namespace
```

**Common causes:**

**Wrong image path/tag:**
```yaml
image:
  repository: "us-phoenix-1.ocir.io/tenancy/customer"  # Verify this exists
  tag: "1.0.0"  # Verify tag exists
```

**Missing or wrong image pull secret:**
```bash
# Verify secret exists
kubectl get secret ocir -n your-namespace

# Test secret (should show JSON with auth)
kubectl get secret ocir -n your-namespace -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

**Recreate if needed:**
```bash
kubectl delete secret ocir -n your-namespace
kubectl create secret docker-registry ocir \
  --docker-server=us-phoenix-1.ocir.io \
  --docker-username='tenancy/user' \
  --docker-password='token' \
  -n your-namespace
```

### Getting More Help

**Gather diagnostic information:**
```bash
# Pod status and events
kubectl get pods -n your-namespace
kubectl describe pod customer-xxx -n your-namespace

# Application logs
kubectl logs deploy/customer -n your-namespace --tail=100

# Environment variables
kubectl exec deploy/customer -n your-namespace -- env | sort

# Helm release
helm list -n your-namespace
helm get values customer -n your-namespace
helm get manifest customer -n your-namespace

# OBaaS platform health
kubectl get all -n <obaas-namespace>
kubectl get configmap obaas-config -n <obaas-namespace> -o yaml
kubectl get configmap obaas-observability-config -n <obaas-namespace> -o yaml
```

## Examples

### Example 1: Production Helidon Service

**values-customer-prod.yaml:**
```yaml
replicaCount: 3

image:
  repository: "us-phoenix-1.ocir.io/mytenancy/customer-helidon"
  tag: "2.1.0"
  pullPolicy: Always

imagePullSecrets:
  - name: ocir

fullnameOverride: "customer"

service:
  type: ClusterIP
  port: 8080

obaas:
  namespace: obaas-prod
  framework: HELIDON

  database:
    credentialsSecret: customer-prod-db-secret
    walletSecret: prod-adb-wallet

  helidon:
    enabled: true
    datasource:
      name: "customer"
    hibernate:
      hbm2ddl_auto: validate  # Never modify prod schema
      show_sql: false
      format_sql: false
    otel:
      serviceName: "customer"

  eureka:
    enabled: true

  otel:
    enabled: true

resources:
  requests:
    cpu: 200m
    memory: 384Mi
  limits:
    cpu: 1000m
    memory: 768Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 2
  failureThreshold: 3
```

**Deploy:**
```bash
helm install customer ./obaas-sample-app \
  -f values-customer-prod.yaml \
  -n production \
  --create-namespace
```

### Example 2: Development Spring Boot Service

**values-order-dev.yaml:**
```yaml
replicaCount: 1

image:
  repository: "us-ashburn-1.ocir.io/mytenancy/order-service"
  tag: "latest"

imagePullSecrets:
  - name: ocir

fullnameOverride: "order"

obaas:
  namespace: obaas-dev
  framework: SPRING_BOOT

  database:
    credentialsSecret: order-dev-db-secret
    walletSecret: dev-adb-wallet

  springboot:
    enabled: true

  eureka:
    enabled: true

  otel:
    enabled: true

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

**Deploy:**
```bash
helm install order ./obaas-sample-app \
  -f values-order-dev.yaml \
  -n development \
  --create-namespace
```

### Example 3: Helidon Service Without Eureka

**values-inventory-standalone.yaml:**
```yaml
image:
  repository: "us-phoenix-1.ocir.io/mytenancy/inventory"
  tag: "1.5.0"

fullnameOverride: "inventory"

obaas:
  namespace: obaas-dev
  framework: HELIDON

  database:
    credentialsSecret: inventory-db-secret
    walletSecret: dev-adb-wallet

  helidon:
    enabled: true
    datasource:
      name: "inventory"
    hibernate:
      hbm2ddl_auto: update
    otel:
      serviceName: "inventory"

  eureka:
    enabled: false  # Standalone service

  otel:
    enabled: true   # Still want observability
```

### Example 4: Multi-Environment with Overlays

**values.yaml** (base):
```yaml
image:
  repository: "us-phoenix-1.ocir.io/mytenancy/customer"
  pullPolicy: Always

imagePullSecrets:
  - name: ocir

fullnameOverride: "customer"

obaas:
  framework: HELIDON
  helidon:
    enabled: true
    datasource:
      name: "customer"
    otel:
      serviceName: "customer"
  eureka:
    enabled: true
  otel:
    enabled: true
```

**values-dev.yaml** (development overlay):
```yaml
image:
  tag: "latest"

replicaCount: 1

obaas:
  namespace: obaas-dev
  database:
    credentialsSecret: customer-dev-db
    walletSecret: dev-wallet
  helidon:
    hibernate:
      hbm2ddl_auto: create
      show_sql: true

resources:
  requests:
    cpu: 50m
    memory: 128Mi
```

**values-prod.yaml** (production overlay):
```yaml
image:
  tag: "2.1.0"

replicaCount: 3

obaas:
  namespace: obaas-prod
  database:
    credentialsSecret: customer-prod-db
    walletSecret: prod-wallet
  helidon:
    hibernate:
      hbm2ddl_auto: validate
      show_sql: false

resources:
  requests:
    cpu: 200m
    memory: 384Mi
  limits:
    cpu: 1000m
    memory: 768Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

**Deploy to environments:**
```bash
# Development
helm install customer ./obaas-sample-app \
  -f values.yaml \
  -f values-dev.yaml \
  -n development

# Production
helm install customer ./obaas-sample-app \
  -f values.yaml \
  -f values-prod.yaml \
  -n production
```

---

## Additional Resources

- [Oracle Backend for Microservices and AI Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [Helidon Documentation](https://helidon.io/docs/latest)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Helm Documentation](https://helm.sh/docs/)
- [SigNoz Documentation](https://signoz.io/docs/)

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
