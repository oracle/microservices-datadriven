# OBaaS And CloudBank Test Agent Runbook

This guide tells an AI agent how to deploy, test, collect evidence, and report on Oracle Backend for Microservices and AI (OBaaS) 2.1.0 with the CloudBank v5 sample workload.

The expected output of a test run is a completed report created from the template in this file, plus an evidence directory containing command output, logs, screenshots, and vulnerability scan results.

## Source Rules

Use only these sources for installation and test truth:

- `AGENTS.md` for OBaaS 2.1.0 planning, installation, and verification.
- `CBV5-AGENT.md` for CloudBank v5 deployment, testing, and cleanup.
- `docs-source/site/docs`, especially `intro.md`, `setup/helm/`, `platform/`, and `observability/`.
- `helm/infra-charts/obaas-prereqs` and `helm/infra-charts/obaas`.
- `cloudbank-v5/README.md`, `cloudbank-v5/cloudbank-v5-install.md`, and `cloudbank-v5/cloudbank-test-doc.md`.
- The task list provided with this guide.
- The SigNoz Services evidence checklist in this guide.

Use only the OBaaS `next` documentation stream for 2.1.0. Do not use 2.0.0 behavior, older CloudBank documentation, or unrelated repository directories.

Do not duplicate command syntax, values-file policy, secrets policy, or cleanup procedure from `AGENTS.md` or `CBV5-AGENT.md` in this file. If those guides conflict with this guide, treat them as canonical for deployment mechanics and treat this guide as canonical for test scope, evidence, and reporting.

## Required Inputs

Collect and record these values before any mutating command:

| Input | Description |
| --- | --- |
| `<kube-context>` | Kubernetes context selected for the run. |
| `<cluster-type>` | OKE, AKS, Rancher Desktop, another public cloud, or on-premises Kubernetes. |
| `<platform-system-namespace>` | Namespace for cluster-singleton prerequisites, for example `obaas-system`. |
| `<prereqs-release>` | Helm release for `obaas-prereqs`, for example `obaas-prereqs`. |
| `<application-namespace>` | Namespace for the OBaaS instance and CloudBank workload. |
| `<app-release>` | Helm release for the OBaaS application chart, for example `obaas`. |
| `<prereqs-values-file>` | Values file for the prerequisites chart, if any. |
| `<app-values-file>` | Values file for the OBaaS application chart. |
| `<database-type>` | `SIDB-FREE`, `ADB-FREE`, `ADB-S`, or `OTHER`. |
| `<storage-class>` | StorageClass selected for persistent components. |
| `<access-path>` | Envoy Gateway, ingress-nginx, both, existing external access, or port-forward-only. |
| `<registry-mode>` | Public registries, private registry, air-gapped, OCIR, or local cluster images. |
| `<cloudbank-dbname>` | Database prefix used by CloudBank scripts. |
| `<cloudbank-image-tag>` | CloudBank image tag, default `0.0.1-SNAPSHOT`. |
| `<cloudbank-registry>` | Explicit image registry path, if not using OCIR auto-detection. |
| `<priv-secret-name>` | Privileged DB secret, usually `<cloudbank-dbname>-db-priv-authn` unless customized. |
| `<evidence-dir>` | Directory for all run evidence and reports. |

Do not proceed with installation until these choices are known. Use placeholders in examples, but never install with unresolved placeholders.

## Cluster Policy

Use `AGENTS.md` as the source of truth for full OBaaS cluster prerequisites and capacity requirements.

Local functional testing may use a one-node cluster such as Rancher Desktop when the goal is smoke, sample workload, or developer-loop validation. In that case:

- Mark the run as `Local Functional`, not `Full Validation`.
- Record deviations from the documented cluster requirements.
- Prefer `SIDB-FREE` only if the node has enough CPU, memory, and ephemeral disk.
- Use port-forward evidence when no external load balancer is available.
- Treat capacity, HA, RWX storage, and external access tests as `Waived` only when the report includes the waiver reason.

## Evidence Layout

Create a fresh evidence directory before running tests:

```bash
export EVIDENCE_DIR=<evidence-dir>
mkdir -p \
  "$EVIDENCE_DIR/cluster" \
  "$EVIDENCE_DIR/helm" \
  "$EVIDENCE_DIR/obaas" \
  "$EVIDENCE_DIR/cloudbank" \
  "$EVIDENCE_DIR/observability" \
  "$EVIDENCE_DIR/security" \
  "$EVIDENCE_DIR/screenshots" \
  "$EVIDENCE_DIR/failures"
```

Capture stdout and stderr for every command that proves a result:

```bash
run_and_capture() {
  name="$1"
  shift
  "$@" >"$EVIDENCE_DIR/$name.out" 2>"$EVIDENCE_DIR/$name.err"
  status=$?
  echo "$status" >"$EVIDENCE_DIR/$name.status"
  return "$status"
}
```

For failures, also capture:

- `kubectl describe` for the failing resource.
- Current and previous pod logs.
- Related jobs and job logs.
- Namespace events sorted by time.
- Helm release status.
- APISIX route output when the failure involves gateway traffic.
- Full HTTP request command, response status, headers, and body.

## Execution Flow

This file does not own deployment mechanics. Use it to decide what must be tested and what evidence must be captured.

1. Prepare the evidence directory and report skeleton from this file.
2. Use `AGENTS.md` for all OBaaS preflight, chart-source selection, values preparation, cert-manager, `obaas-prereqs`, OBaaS install, uninstall, and reinstall commands.
3. After each OBaaS phase, return to the master test matrix in this file and record status, evidence paths, and failures.
4. Use `CBV5-AGENT.md` for all CloudBank v5 prerequisite checks, image handling, secret creation, service deployment, APISIX route creation, smoke tests, manual endpoint tests, and cleanup commands.
5. After each CloudBank phase, return to the master test matrix in this file and record status, evidence paths, and failures.
6. Use the observability, security, lifecycle, isolation, and report sections in this file for test coverage that is broader than either deployment guide.
7. Do not continue from OBaaS installation to CloudBank deployment until all required OBaaS health checks in the matrix are passing or explicitly waived.
8. Do not mark a test run complete until the report template in this file is filled out and all required evidence has been captured.

The exact commands, flags, values files, secret names, and cleanup procedures must come from `AGENTS.md` and `CBV5-AGENT.md` at execution time.

## Master Test Matrix

Use this matrix as the master list for each run. Mark each test `Pass`, `Fail`, `Waived`, or `Not Applicable`.

| ID | Category | Test | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| PRE-001 | Preflight | Verify current Kubernetes context. | Context equals `<kube-context>`. | `kubectl config current-context` |
| PRE-002 | Preflight | Verify cluster API access. | `kubectl get nodes` succeeds. | node list |
| PRE-003 | Preflight | Verify Helm access. | `helm version` and `helm list -A` succeed. | Helm output |
| PRE-004 | Preflight | Verify cluster capacity policy. | Full validation meets requirements, or local deviations are recorded. | node describe |
| PRE-005 | Preflight | Verify storage classes and RWX support decision. | Selected storage class and RWX status are recorded. | storageclass output |
| PRE-006 | Preflight | Verify external access strategy. | Envoy Gateway, ingress-nginx, both, or port-forward-only path is documented. | service, ingress, gateway output |
| PRE-007 | Preflight | Verify chart source. | Local 2.1.0 chart paths are used unless public charts match target version. | Chart.yaml and Helm search output |
| INST-001 | Install | Install or verify cert-manager. | cert-manager deployments are available and CRDs exist. | pod, wait, CRD output |
| INST-002 | Install | Install `obaas-prereqs` once. | Release deployed and prerequisite pods healthy. | Helm status and pod output |
| INST-003 | Install | Install OBaaS. | Release deployed and OBaaS pods healthy. | Helm status and pod output |
| INST-004 | Install | Verify no unexpected failed jobs or PVC problems. | Jobs succeeded and PVCs bound. | jobs, PVCs, events |
| PLAT-001 | Platform | Verify APISIX gateway. | Gateway service has external address or working port-forward. | service output, curl result |
| PLAT-002 | Platform | Verify APISIX admin API. | Admin routes endpoint responds with valid admin key. | curl output |
| PLAT-003 | Platform | Verify Eureka. | Eureka UI/API is reachable. | screenshot and HTTP output |
| PLAT-004 | Platform | Verify Config Server. | `/<application>/<profile>` returns JSON property source response. | curl output |
| PLAT-005 | Platform | Verify Spring Boot Admin. | Admin UI is reachable and services appear. | screenshot |
| PLAT-006 | Platform | Verify database exporter. | Exporter pod/service is healthy and metrics scrape target exists. | pod, service, logs |
| PLAT-007 | Platform | Verify OTMM/MicroTx. | OTMM service is healthy and transfer workflow can use it. | pod output and CloudBank transfer evidence |
| PLAT-008 | Platform | Verify optional Kafka. | Kafka CRs and dashboard data exist when Kafka is enabled. | Strimzi/Kafka output |
| PLAT-009 | Platform | Verify optional AI Optimizer. | AI Optimizer pods and required secrets exist when enabled. | pod, secret output |
| PLAT-010 | Platform | Verify optional workflow server or console. | Optional components are healthy when enabled. | pod, service, screenshot |
| CB-001 | CloudBank | Run CloudBank prerequisite checks. | Build and deploy checks pass. | script output |
| CB-002 | CloudBank | Build and publish or load images. | Seven images are available to the cluster. | build/push output |
| CB-003 | CloudBank | Create CloudBank secrets. | Expected DB, OAuth, and signing-key secrets exist. | secret list |
| CB-004 | CloudBank | Deploy seven services. | `azn-server`, `account`, `customer`, `creditscore`, `transfer`, `checks`, `testrunner` are running. | Helm and pod output |
| CB-005 | CloudBank | Create APISIX routes. | Required routes created and sensitive routes blocked. | route script output |
| CB-006 | CloudBank | Run secured smoke test. | Smoke test passes. | smoke script output |
| CB-007 | CloudBank | Check OAuth metadata and JWKS. | Metadata is public and JWKS exposes a key ID. | curl output |
| CB-008 | CloudBank | Check unauthorized access. | Protected endpoint without token returns `401`. | curl output |
| CB-009 | CloudBank | Check read access. | Read token can call account, customer, and creditscore APIs. | curl output |
| CB-010 | CloudBank | Check wrong-scope access. | Wrong token scope returns `403`. | curl output |
| CB-011 | CloudBank | Check deposit workflow. | Deposit returns success and check service logs show receipt. | curl and logs |
| CB-012 | CloudBank | Check journal and clearance workflow. | Journal moves from pending to deposit after clear. | curl and logs |
| CB-013 | CloudBank | Check transfer workflow. | Balances change correctly and transfer logs show LRA lifecycle. | curl and logs |
| OBS-001 | Observability | Log in to SigNoz. | SigNoz UI login succeeds. | screenshot |
| OBS-002 | Observability | Verify SigNoz Services view. | Platform and CloudBank services appear for recent time window. | screenshot |
| OBS-003 | Observability | Verify Services table columns. | P99 latency, error rate, and operations per second are populated. | screenshot |
| OBS-004 | Observability | Verify traces. | CloudBank request traces appear and can be opened. | screenshot |
| OBS-005 | Observability | Verify logs. | CloudBank and platform logs appear and can be filtered by namespace/pod/service. | screenshot |
| OBS-006 | Observability | Verify metrics. | Service metrics are visible for CloudBank and platform services. | screenshot |
| OBS-007 | Observability | Verify infra monitoring. | Kubernetes node, pod, PVC, and host metrics are visible where supported. | screenshot |
| OBS-008 | Observability | Verify dashboards are installed. | Expected preinstalled dashboards are present. | screenshot and dashboard list |
| OBS-009 | Observability | Verify dashboard population. | Key dashboards show current data after generated traffic. | screenshots |
| OBS-010 | Observability | Verify DB observability. | Oracle Database and DB Calls dashboards show data. | screenshots |
| OBS-011 | Observability | Verify APISIX observability. | APISIX dashboard shows gateway request data. | screenshot |
| OBS-012 | Observability | Verify JVM/Spring observability. | Spring Boot and JVM dashboards show CloudBank data. | screenshots |
| OBS-013 | Observability | Verify MicroTx observability. | MicroTx dashboard shows data after transfer workflow, or waiver explains absence. | screenshot |
| OBS-014 | Observability | Verify messaging queues view. | Messaging Queues view is accessible and populated when queue/Kafka data exists. | screenshot |
| SEC-001 | Security | Scan OBaaS images. | Scanner completes and critical/high findings are triaged. | scan report |
| SEC-002 | Security | Scan CloudBank images. | Scanner completes and critical/high findings are triaged. | scan report |
| SEC-003 | Security | Record scanner metadata. | Scanner name, version, DB date, image tags, and digests are recorded. | scan output |
| LIFE-001 | Lifecycle | Uninstall OBaaS chart when explicitly approved. | Namespace-scoped resources are removed or expected retained resources are documented. | Helm/kubectl output |
| LIFE-002 | Lifecycle | Reinstall OBaaS into same namespace. | Install succeeds after cleanup. | Helm/kubectl output |
| MT-001 | Multi-OBaaS | Install second OBaaS in different namespace. | Second release is healthy. | Helm/kubectl output |
| MT-002 | Multi-OBaaS | Verify Eureka isolation. | Each Eureka instance sees only its namespace's services. | screenshots |
| MT-003 | Multi-OBaaS | Verify SigNoz isolation. | Each SigNoz instance shows only its namespace's telemetry. | screenshots |
| DB-001 | BYODB | Test `database.type: OTHER` when available. | OBaaS installs against BYODB and required grants are verified. | SQL and Helm output |

## Functional Test Guidance

Use `AGENTS.md`, `CBV5-AGENT.md`, and the local platform documentation for exact commands. This section defines only the additional system-test expectations.

Platform checks:

- APISIX gateway must be reachable through the selected access path or a documented local port-forward.
- APISIX admin API must show the route set expected after CloudBank route creation.
- Eureka must show the OBaaS platform services and all seven CloudBank services after deployment.
- Config Server must respond. If no test property is seeded, record that the server is reachable and that no config data validation was performed.
- Spring Boot Admin must show monitored Spring services and health status.

CloudBank checks:

- Run the automated secured smoke test from `CBV5-AGENT.md` first and preserve its full output.
- Run any additional manual endpoint checks from `cloudbank-v5/cloudbank-test-doc.md` only when they add evidence not already covered by the smoke test.
- Verify OAuth metadata and JWKS reachability, unauthorized access rejection, wrong-scope rejection, read-token success, deposit/journal/clearance behavior, transfer behavior, and expected workflow logs.
- Use HTTPS for external gateway URLs. Use local port-forwarding only for local test clusters or isolated evidence capture.

Screenshots:

- Capture Eureka and Spring Boot Admin UI evidence with Selenium or an equivalent browser automation tool.
- For any UI that cannot be captured, record the exact access method used, browser or automation error, related service state, and related logs.

## Observability Test Requirements

Use the following SigNoz Services checklist as the minimum UI evidence requirement for enterprise observability validation.

### SigNoz Services Checklist

Capture the SigNoz UI on the `Services` page with these visible elements:

- SigNoz Enterprise branding.
- The displayed SigNoz version.
- Left navigation with `Services` selected.
- Left navigation entries for `Traces`, `Logs`, `Metrics`, `Infra Monitoring`, `Dashboards`, and `Messaging Queues`.
- A top refresh indicator showing a recent refresh, for example `Refreshed 8 sec ago`.
- Time range set to `Last 30 minutes`.
- Refresh and share controls visible.
- A resource attribute search/filter bar above the table.
- A services table with sortable columns:
  - service name
  - `P99 latency (in ms)`
  - `Error Rate (% of total)`
  - `Operations Per Second`
- Multiple service rows with numeric latency, error-rate, and operations-per-second values.

Evidence requirements:

- Capture the page after CloudBank traffic has been generated.
- Use a recent time window, preferably `Last 30 minutes`.
- Ensure the screenshot includes the refresh timestamp, selected time range, service rows, and the `P99 latency (in ms)`, `Error Rate (% of total)`, and `Operations Per Second` columns.
- The service-name column must be readable. If names are cropped or hidden, take another screenshot with the sidebar collapsed, a wider viewport, or horizontal scroll adjusted.
- At least the CloudBank services and OBaaS platform services should appear in the services list after traffic and platform checks.
- Numeric values must be present, not blank or `No data`.
- `Operations Per Second` values of `0.00` are acceptable only when the report also includes curl or smoke-test evidence proving traffic occurred within the selected time range. Prefer capturing the screenshot while traffic is active so at least some services show non-zero operations per second.
- Error-rate values must be explained. Expected negative tests such as `401` and `403` may contribute to visible error rates; unexplained high error rates must be investigated with logs, traces, and failed HTTP evidence.

### Access SigNoz

Use the SigNoz access procedure from `docs-source/site/docs/observability/access.md` for the current chart version and selected release name. Record the credential source, access method, and URL in the run report without printing passwords into committed files.

### Required SigNoz Screenshots

Capture evidence for:

- Services list with platform and CloudBank services.
- Services table showing P99 latency, error rate, and operations per second.
- A CloudBank service metrics detail page.
- Traces list filtered to CloudBank traffic.
- A trace detail page showing cross-service timing.
- Logs filtered by `<application-namespace>` and at least one CloudBank service.
- Log detail page showing context and trace correlation when available.
- Metrics explorer or service metrics view.
- Infra Monitoring view for Kubernetes nodes, pods, PVCs, or host metrics.
- Dashboards list showing preinstalled dashboards.
- At least these populated dashboards after generated traffic:
  - Spring Boot Observability
  - Spring Boot 3.x Statistics
  - Oracle Database Dashboard
  - kube-state-metrics-v2
  - Apache APISIX
  - Envoy Gateway Dashboard, if Envoy Gateway is enabled
  - APM Metrics
  - Kubernetes Pod Metrics - Overall
  - Kubernetes Pod Metrics - Detailed
  - Kubernetes PVC Metrics
  - Kubernetes Node Metrics - Overall
  - Kubernetes Node Metrics - Detailed
  - DB Calls Monitoring
  - Host Metrics (k8s)
  - HTTP API Monitoring
  - JVM Metrics
  - NGINX (OTEL), if ingress-nginx is enabled
  - MicroTx
  - Kafka Server Monitoring Dashboard, if Kafka is enabled
  - Helidon dashboards, only when Helidon workloads are deployed

### Selenium Evidence Capture

Use Selenium WebDriver or an equivalent Selenium-compatible driver. Store screenshots under `$EVIDENCE_DIR/screenshots`.

Minimum screenshot naming convention:

```text
screenshots/signoz-01-login.png
screenshots/signoz-02-services.png
screenshots/signoz-03-service-detail-cloudbank.png
screenshots/signoz-04-traces.png
screenshots/signoz-05-trace-detail.png
screenshots/signoz-06-logs.png
screenshots/signoz-07-dashboards-list.png
screenshots/signoz-08-dashboard-spring-boot-observability.png
screenshots/signoz-09-dashboard-http-api.png
screenshots/signoz-10-dashboard-db-calls.png
screenshots/eureka-services.png
screenshots/spring-boot-admin-services.png
screenshots/apisix-dashboard.png
```

If a UI cannot be accessed, mark the related test `Fail` and capture:

- Port-forward command output.
- Browser or Selenium error.
- Related service, pod, and endpoint output.
- Related logs.

## Vulnerability Scanning

Scan all OBaaS and CloudBank images that are deployed or rendered by the selected values files.

Use Trivy by default:

```bash
trivy version
trivy image --format json --output "$EVIDENCE_DIR/security/<image-name>.trivy.json" <image-ref>
trivy image --severity CRITICAL,HIGH --exit-code 1 <image-ref>
```

Use Grype as fallback when Trivy is unavailable:

```bash
grype version
grype -o json <image-ref> >"$EVIDENCE_DIR/security/<image-name>.grype.json"
grype --fail-on high <image-ref>
```

For each image, record:

- Scanner name and version.
- Scanner vulnerability database date, when available.
- Image reference.
- Image digest, when available.
- Total vulnerabilities by severity.
- Critical and high findings.
- Whether findings are fixed, unfixed, or accepted by an approved exception.

Mark the security test `Fail` when critical or high findings exist without a documented exception. Mark it `Waived` only when the operator explicitly accepts the risk and the waiver records the image, CVE, severity, reason, approver, and expiration date.

## Lifecycle And Isolation Tests

Run destructive lifecycle tests only with explicit operator approval and only after CloudBank sample data can be destroyed.

### Uninstall And Reinstall

1. Uninstall CloudBank using `CBV5-AGENT.md` cleanup steps.
2. Uninstall OBaaS using `AGENTS.md` cleanup or uninstall guidance for the selected installation type.
3. Verify the namespace is empty except for explicitly retained or approved resources.
4. Reinstall OBaaS into the same namespace using the same values.
5. Rerun platform and CloudBank smoke tests.

### Multi-OBaaS

Install a second OBaaS instance in a different namespace using the multi-tenant guidance and values policy in `AGENTS.md`.

Expected:

- Each OBaaS release is healthy.
- Each Eureka instance shows only services from its namespace.
- Each SigNoz instance shows only telemetry from its namespace.
- Ingress-nginx class names, controller values, and election IDs are unique when ingress-nginx is enabled for both tenants.

### BYODB

Run only when an external non-Autonomous Oracle Database is available and the privileged user has required grantable privileges.

Expected:

- `database.type: OTHER` values are used.
- DSN or host, port, and service name are correct.
- Privileged secret exists.
- Required `SELECT WITH GRANT OPTION` and `EXECUTE WITH GRANT OPTION` privileges are verified.
- OBaaS installs and CloudBank smoke tests pass.

## Failure Evidence

When any test fails, collect the relevant diagnostics from `AGENTS.md`, `CBV5-AGENT.md`, and the local platform docs, then attach them to the report. At minimum, evidence should cover:

- Current namespace workload state.
- Relevant Helm release status.
- Current and previous logs for failing pods.
- `describe` output for failing pods, jobs, PVCs, services, ingress, Gateway API resources, or other implicated resources.
- Namespace events sorted by time.
- Failed job logs, especially database initialization jobs.
- Gateway route or APISIX Admin API output for route, auth, or gateway failures.
- HTTP request and response evidence for endpoint failures.
- SigNoz, ClickHouse, OpenTelemetry collector, instrumentation, and application telemetry configuration evidence for observability failures.
- Browser automation error details for UI or screenshot failures.

## Run Report Template

Create one report per run at:

```text
<evidence-dir>/TEST-RUN-REPORT.md
```

Use this template:

```markdown
# OBaaS And CloudBank Test Run Report

## Run Metadata

| Field | Value |
| --- | --- |
| Run ID |  |
| Start Time |  |
| End Time |  |
| Tester / Agent |  |
| Repository Commit |  |
| Kubernetes Context |  |
| Cluster Type |  |
| Validation Tier | Full Validation / Local Functional |
| Platform Namespace |  |
| Prereqs Release |  |
| Application Namespace |  |
| OBaaS Release |  |
| OBaaS Chart Version |  |
| OBaaS App Version |  |
| Database Type |  |
| Access Path |  |
| CloudBank DB Name |  |
| CloudBank Image Tag |  |
| Evidence Directory |  |

## Executive Summary

Overall Status: Pass / Fail

Traffic-Light Rating: Green / Amber / Red

Pass Rate: `<passed>/<executed>` (`<percent>%`)

Summary:

- 

Rating rules:

- Green: all required tests pass, no unwaived critical/high image findings, no required evidence missing.
- Amber: only waived, local-capacity, optional-component, or non-blocking evidence issues remain.
- Red: any required install, platform, CloudBank, observability, isolation, or security test fails.

## Environment Summary

Cluster capacity:

- 

Storage:

- 

Network and access:

- 

Known deviations or waivers:

- 

## Test Results

| ID | Category | Status | Expected | Actual | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| PRE-001 | Preflight |  |  |  |  |  |
| INST-001 | Install |  |  |  |  |  |
| PLAT-001 | Platform |  |  |  |  |  |
| CB-001 | CloudBank |  |  |  |  |  |
| OBS-001 | Observability |  |  |  |  |  |
| SEC-001 | Security |  |  |  |  |  |

## Observability Evidence Summary

| View / Dashboard | Status | Evidence | Notes |
| --- | --- | --- | --- |
| SigNoz Services |  |  |  |
| Services P99/Error Rate/OPS Columns |  |  |  |
| Traces |  |  |  |
| Logs |  |  |  |
| Metrics |  |  |  |
| Infra Monitoring |  |  |  |
| Dashboards List |  |  |  |
| Spring Boot Observability |  |  |  |
| Spring Boot Statistics |  |  |  |
| Oracle Database Dashboard |  |  |  |
| APISIX Dashboard |  |  |  |
| HTTP API Monitoring |  |  |  |
| DB Calls Monitoring |  |  |  |
| JVM Metrics |  |  |  |
| MicroTx |  |  |  |

## Security Scan Summary

| Image | Scanner | Digest | Critical | High | Medium | Low | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  |

Exceptions:

| Image | CVE | Severity | Reason | Approver | Expiration |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Failure Diagnostics

| Test ID | Symptom | Evidence | Likely Cause | Recommended Action |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Sign-Off

| Role | Name | Date | Notes |
| --- | --- | --- | --- |
| Tester |  |  |  |
| Reviewer |  |  |  |
| Operator Approval For Waivers |  |  |  |
```

## Completion Criteria

A run is complete only when:

- The selected installation tier is explicitly recorded.
- Required install and platform tests are complete.
- CloudBank deployment and smoke tests are complete.
- Observability evidence includes SigNoz Services, traces, logs, metrics, dashboards, and dashboard-population screenshots.
- Vulnerability scans are complete or explicitly waived by the operator.
- Every failure has logs, events, command output, and a recommended next action.
- The run report contains an overall pass/fail result, pass rate, traffic-light rating, and evidence links.
