# OBaaS Sample Application Helm Chart

Deploying microservices to Kubernetes typically means maintaining separate Helm charts for Spring Boot and Helidon applications, or worse—writing framework-specific conditional logic throughout your application code. This chart takes a different approach: **one chart, one parameter, automatic configuration**.

Whether you're building with Spring Boot or Helidon, this chart automatically wires up database connections, service discovery, health checks, and observability—all based on a single `framework` parameter in your values file.

## How It Works

The chart uses Helm's templating engine to detect your framework choice and inject the appropriate environment variables, probe configurations, and metrics endpoints. When you deploy a Helidon application, you get `/health/live` probes and MicroProfile-style datasource configuration. Choose Spring Boot instead, and you automatically get `/actuator/health/liveness` endpoints and Spring-style environment variables.

Behind the scenes, the deployment template queries your OBaaS platform's ConfigMaps to retrieve Eureka URLs, SigNoz collector endpoints, and other platform-wide settings. This means you never hardcode connection strings or service endpoints—everything adapts to your environment automatically.

Your application pods start with their Oracle Autonomous Database wallet already mounted at `/oracle/tnsadmin`, database credentials injected from Kubernetes secrets, and OpenTelemetry configured to push metrics to SigNoz. Service discovery happens automatically if you enable Eureka, and health probes use the correct endpoints for your framework.

## What You Get

This chart eliminates configuration boilerplate by automatically setting up:

- **Framework-appropriate health checks**: The right probe paths for Spring Boot (`/actuator/health/*`) or Helidon (`/health/*`)
- **Database integration**: Wallet mounting, connection string injection, and framework-specific datasource configuration
- **Service discovery**: Eureka registration with hostname and zone settings pulled from your OBaaS platform
- **Observability**: OpenTelemetry integration pushing metrics, traces, and logs to SigNoz, plus Prometheus scraping annotations
- **Production readiness**: Resource limits, horizontal pod autoscaling, and configurable probe timings

The deployment template includes over 150 lines of framework-specific environment variable configuration, all selected automatically based on your choice. Spring Boot applications receive `SPRING_DATASOURCE_*` variables and Spring Cloud Config integration. Helidon applications get MicroProfile Config-style `javax.sql.DataSource.*` properties and explicit OTLP protocol settings to work around Helidon's OpenTelemetry quirks.

## Before You Begin

Your Kubernetes cluster needs an OBaaS installation before this chart can render templates. The chart uses Helm's `lookup` function to retrieve platform configuration from ConfigMaps, which means you can't fully render templates without a live cluster connection. Verify your platform is ready:

```bash
kubectl get configmap obaas-config -n <obaas-namespace>
kubectl get configmap obaas-observability-config -n <obaas-namespace>
```

You'll also need three secrets in your target namespace: database credentials (username, password, and service name), an Autonomous Database wallet (the ZIP file from OCI Console, unzipped), and optionally an image pull secret for private registries.

For database credentials, create a generic secret with keys `db.username`, `db.password`, and `db.service` (the TNS service name from your wallet's `tnsnames.ora`). Spring Boot applications using Liquibase for schema migrations need two additional keys: `db.lb_username` and `db.lb_password` for the admin user.

The wallet secret should contain all files from your ADB wallet ZIP—`tnsnames.ora`, `sqlnet.ora`, `cwallet.sso`, and the various keystore files. The chart mounts this secret as a volume at `/oracle/tnsadmin`, and the JDBC connection string references this path automatically.

## Getting Started

Start by creating a custom values file for your application. The chart's default `values.yaml` contains placeholders with `TODO` comments marking required changes. Copy it and fill in your specifics:

```yaml
image:
  repository: "us-ashburn-1.ocir.io/mytenancy/customer-helidon"
  tag: "1.0.0"

imagePullSecrets:
  - name: ocir

fullnameOverride: "customer"

obaas:
  namespace: obaas-dev
  framework: HELIDON  # or SPRING_BOOT

  database:
    credentialsSecret: customer-db-secret
    walletSecret: dev-adb-wallet

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

Notice the `obaas.helidon.datasource.name` and `obaas.helidon.otel.serviceName` settings. These are **critical** for Helidon deployments—the datasource name must match your application's `microprofile-config.properties`, and the OTEL service name must match your `otel.service.name` property. Mismatches cause runtime "DataSource not found" errors or metrics appearing under the wrong service in SigNoz.

Spring Boot deployments are simpler because Spring's convention-over-configuration approach means fewer explicit mappings. Just set `framework: SPRING_BOOT`, enable `obaas.springboot.enabled: true`, and the chart handles the rest.

Deploy with Helm:

```bash
helm install customer ./obaas-sample-app \
  -f values-customer.yaml \
  -n your-namespace \
  --create-namespace
```

Check that your pod starts successfully:

```bash
kubectl get pods -n your-namespace
kubectl logs -f deployment/customer -n your-namespace
```

If you see connection errors, verify your secrets exist and contain the correct keys. Database authentication failures usually mean typos in `db.username` or `db.password`. TNS resolution errors mean `db.service` doesn't match an entry in your wallet's `tnsnames.ora`.

## Framework Differences That Matter

Spring Boot and Helidon have different conventions for database configuration, health checks, and metrics. The chart handles these differences automatically, but understanding them helps when troubleshooting.

**Spring Boot** uses Spring Data JPA and Spring Boot Actuator. Database settings go in `SPRING_DATASOURCE_*` environment variables, and Spring automatically configures connection pooling. Health endpoints appear under `/actuator/health/`, and metrics use Micrometer with Prometheus export at `/actuator/prometheus`. Eureka integration happens through Spring Cloud Netflix, with service registration managed by Spring's `@EnableDiscoveryClient` annotation.

**Helidon** follows the MicroProfile specification. Database configuration uses `javax.sql.DataSource.<name>.*` properties where the name maps to your application's datasource bean. Helidon doesn't auto-configure datasources like Spring does—you must explicitly match the datasource name between your `microprofile-config.properties` and your Helm values. Health endpoints are simpler paths: `/health/live` and `/health/ready`. Metrics follow MicroProfile Metrics at `/metrics`, and OpenTelemetry requires explicit protocol configuration (`http/protobuf` instead of gRPC) to work with SigNoz.

Resource-wise, Helidon is lighter. A typical Helidon microservice idles around 200-350 MB of memory and starts in 3-8 seconds, compared to Spring Boot's 350-500 MB and 8-15 second startup. Production Helidon deployments can run comfortably with 100m CPU and 256 Mi memory requests, while Spring Boot typically needs 250m CPU and 512 Mi to avoid throttling under load.

## Observability and Debugging

Every pod deployed by this chart includes OpenTelemetry integration pushing metrics to your OBaaS platform's SigNoz installation. Metrics flow two ways: OTLP push (the pod actively sends metrics via HTTP) and Prometheus scraping (SigNoz pulls from your `/metrics` endpoint). The chart sets pod annotations (`signoz.io/scrape: "true"`) to enable scraping and injects OTEL environment variables for push.

Helidon has a quirk: it defaults to gRPC for OTLP, which doesn't work with many SigNoz installations. The chart works around this by explicitly setting `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` and enabling Java's global OpenTelemetry auto-configuration via `JAVA_TOOL_OPTIONS`. Without these settings, you'll see "failed to export" errors in your logs and metrics won't appear in SigNoz.

When metrics don't show up in SigNoz, the debugging process is straightforward. Port-forward to your pod and curl the metrics endpoint directly—if it returns data, the problem is with OTEL export or scraping configuration. If it returns a 404, your application isn't exposing metrics correctly. Check that Spring Boot Actuator is enabled or Helidon Metrics is in your dependencies.

Query SigNoz metrics using Kubernetes metadata filters. Metrics are tagged with `k8s_pod_name` (includes your Helm release name), `k8s_namespace_name`, and `service_name`. The service name comes from your OTEL configuration for Helidon applications, or defaults to "signoz-scraper" for Prometheus-scraped metrics from Spring Boot.

Health probe failures usually mean one of two things: slow startup or failed dependencies. Increase `livenessProbe.initialDelaySeconds` to 60 seconds if your application takes time to initialize. If your readiness probe fails immediately after startup, it's often because the database connection hasn't established—increase `readinessProbe.initialDelaySeconds` and `failureThreshold` to give the pod more time.

## Configuration Patterns

Most teams deploy the same application to multiple environments with different settings. Use value overlays to keep environment-specific config separate from base settings:

Create a base `values.yaml` with common settings:

```yaml
image:
  repository: "us-phoenix-1.ocir.io/mytenancy/customer"
  pullPolicy: Always

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

Then create environment overlays like `values-dev.yaml`:

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
      hbm2ddl_auto: create  # Auto-create schema in dev
      show_sql: true        # Show SQL for debugging
```

And `values-prod.yaml` with production settings:

```yaml
image:
  tag: "2.1.0"  # Pinned version

replicaCount: 3

obaas:
  namespace: obaas-prod
  database:
    credentialsSecret: customer-prod-db
    walletSecret: prod-wallet
  helidon:
    hibernate:
      hbm2ddl_auto: validate  # Never modify prod schema
      show_sql: false         # No debug output

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
```

Deploy by layering multiple value files:

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

Later values files override earlier ones, so environment-specific settings replace base defaults.

## Managing Secrets

Database credentials and wallet files are sensitive—never commit them to version control. Create secrets imperatively from local files or secure storage:

```bash
# Database credentials
kubectl create secret generic customer-db-secret \
  --from-literal=db.username=CUSTOMER_USER \
  --from-literal=db.password='SecurePassword123!' \
  --from-literal=db.service=myatp_high \
  -n your-namespace
```

For Spring Boot with Liquibase:

```bash
kubectl create secret generic customer-db-secret \
  --from-literal=db.username=CUSTOMER_USER \
  --from-literal=db.password='SecurePassword123!' \
  --from-literal=db.service=myatp_high \
  --from-literal=db.lb_username=ADMIN \
  --from-literal=db.lb_password='AdminPassword456!' \
  -n your-namespace
```

ADB wallet secrets need all files from the wallet ZIP:

```bash
unzip Wallet_MyATP.zip -d /tmp/wallet/
kubectl create secret generic customer-adb-wallet \
  --from-file=/tmp/wallet/ \
  -n your-namespace
rm -rf /tmp/wallet  # Clean up
```

Verify secrets contain the expected keys:

```bash
kubectl get secret customer-db-secret -n your-namespace -o jsonpath='{.data}' | jq 'keys'
```

Image pull secrets for private registries follow Kubernetes' standard format:

```bash
kubectl create secret docker-registry ocir \
  --docker-server=us-phoenix-1.ocir.io \
  --docker-username='tenancy-namespace/oracleidentitycloudservice/user@example.com' \
  --docker-password='your-auth-token' \
  -n your-namespace
```

Reference the secret in your values file:

```yaml
imagePullSecrets:
  - name: ocir
```

## Common Problems

**Pods in CrashLoopBackOff** with database connection errors mean your credentials secret is missing, has wrong keys, or contains incorrect values. Check that `db.service` matches a service name in your `tnsnames.ora`. Oracle returns "TNS: could not resolve the connect identifier" when the service name doesn't exist in your wallet.

**Helidon "DataSource not found" errors** happen when `obaas.helidon.datasource.name` in your values file doesn't match your application's datasource bean name. Check environment variables in the running pod:

```bash
kubectl exec deploy/customer -n your-namespace -- env | grep javax.sql.DataSource
```

The datasource name appears in the middle of the variable names. It must match your `microprofile-config.properties` exactly.

**Metrics not appearing in SigNoz** usually means OTEL configuration issues. For Helidon, verify the protocol is set correctly:

```bash
kubectl exec deploy/customer -n your-namespace -- env | grep OTEL
```

You should see `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`. If it's missing or set to `grpc`, metrics won't export. Check your application logs for "failed to export" errors.

**ImagePullBackOff errors** mean Kubernetes can't pull your container image. Verify the image path and tag are correct, and that your image pull secret exists and has valid credentials:

```bash
kubectl get secret ocir -n your-namespace -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

The decoded JSON should contain your registry credentials.

**Health probe failures** show as pods that never become Ready or that restart frequently. Port-forward to the pod and manually test the health endpoints:

```bash
kubectl port-forward deploy/customer 8080:8080 -n your-namespace

# Helidon
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready

# Spring Boot
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness
```

If endpoints return errors or don't exist, check that you've included the correct dependencies (Spring Boot Actuator or Helidon Health) and that your application framework matches the chart's `framework` setting.

## Helm Operations

Beyond basic installation, you'll need to update deployments, debug template rendering, and inspect running releases.

Upgrade a deployed release with new values:

```bash
helm upgrade customer ./obaas-sample-app \
  -f values-customer.yaml \
  -n your-namespace
```

Render templates locally without installing (requires cluster access to query ConfigMaps):

```bash
helm template customer ./obaas-sample-app \
  -f values-customer.yaml \
  --debug
```

Inspect what's actually deployed:

```bash
# Show current values
helm get values customer -n your-namespace

# Show rendered Kubernetes manifests
helm get manifest customer -n your-namespace

# List all releases
helm list -n your-namespace
```

Validate your chart before deploying:

```bash
helm lint ./obaas-sample-app -f values-customer.yaml
```

Uninstall a release (keeps namespace):

```bash
helm uninstall customer -n your-namespace
```

## Additional Resources

- [Oracle Backend for Microservices and AI Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [Helidon Documentation](https://helidon.io/docs/latest)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Helm Documentation](https://helm.sh/docs/)
- [SigNoz Documentation](https://signoz.io/docs/)

## License

Copyright (c) 2025 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
