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
- `Checklist for enterprise level a_adefff5e0ee44eaea28fb4a1bd57d633-030326-1241-6752.pdf`.
- The task list provided with this guide.

Use only the OBaaS `next` documentation stream for 2.1.0. Do not use 2.0.0 behavior, older CloudBank documentation, or unrelated repository directories.

For OBaaS 2.1.0 testing, use local chart paths under `helm/infra-charts` unless the public Helm repository has already published charts whose `APP VERSION` or `appVersion` matches the target 2.1.0 version. If the public repository still advertises 2.0.0 or another non-2.1.0 version, do not install or test with public `obaas/obaas-prereqs` or `obaas/obaas` references.

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

OBaaS documented full validation expects:

- Kubernetes 1.34 or later.
- At least 3 worker nodes.
- At least 2 OCPU and 32 GB memory per worker node.
- A working storage provider with `ReadWriteMany` support where required.
- A working external access path through Ingress or Gateway API.

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

## Installation Procedure

### 1. Preflight

Record local tool and cluster access evidence:

```bash
kubectl config current-context
kubectl version
kubectl get nodes -o wide
kubectl describe nodes
kubectl get storageclass
kubectl get ns
kubectl get ingressclass
kubectl get gatewayclass
helm version
helm list -A
```

Expected:

- Current context is `<kube-context>`.
- The agent can list nodes, namespaces, storage classes, and Helm releases.
- The target cluster policy is recorded as `Full Validation` or `Local Functional`.
- Storage and access-path limitations are documented before installation.

### 2. Confirm Chart Source

Record local chart versions:

```bash
grep '^version:' helm/infra-charts/obaas-prereqs/Chart.yaml
grep '^appVersion:' helm/infra-charts/obaas-prereqs/Chart.yaml
grep '^version:' helm/infra-charts/obaas/Chart.yaml
grep '^appVersion:' helm/infra-charts/obaas/Chart.yaml
```

If comparing public charts, record:

```bash
helm repo add obaas https://oracle.github.io/microservices-backend/helm
helm repo update
helm search repo obaas/obaas-prereqs --versions
helm search repo obaas/obaas --versions
```

Expected:

- Use local chart paths when public `APP VERSION` does not match the target 2.1.0 application version.
- Use these local chart paths for in-development 2.1.0 tests:
  - `helm/infra-charts/obaas-prereqs`
  - `helm/infra-charts/obaas`

### 3. Lint And Render

Lint and render before installing whenever values are available:

```bash
helm lint helm/infra-charts/obaas-prereqs -f <prereqs-values-file>
helm lint helm/infra-charts/obaas -f <app-values-file>
helm template <prereqs-release> helm/infra-charts/obaas-prereqs \
  -n <platform-system-namespace> \
  -f <prereqs-values-file> >"$EVIDENCE_DIR/helm/obaas-prereqs-rendered.yaml"
helm template <app-release> helm/infra-charts/obaas \
  -n <application-namespace> \
  -f <app-values-file> >"$EVIDENCE_DIR/helm/obaas-rendered.yaml"
```

If no prerequisite values file is used, omit the `-f <prereqs-values-file>` argument.

Expected:

- `helm lint` succeeds.
- Rendered manifests are saved as evidence.
- Optional components selected in values match the test scope.

### 4. cert-manager

If cert-manager is not installed and healthy, install it before `obaas-prereqs`:

```bash
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.19.4 \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --set crds.keep=false
```

Verify:

```bash
kubectl get pods -n cert-manager
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=5m
kubectl get crd | grep cert-manager
```

Expected: cert-manager pods are healthy and cert-manager CRDs exist.

### 5. Install Cluster Prerequisites

Install `obaas-prereqs` once per cluster:

```bash
helm upgrade --install <prereqs-release> helm/infra-charts/obaas-prereqs \
  -n <platform-system-namespace> \
  --create-namespace \
  -f <prereqs-values-file>
```

If no custom prerequisite values are needed, omit `-f <prereqs-values-file>`.

Verify:

```bash
helm status <prereqs-release> -n <platform-system-namespace>
kubectl get pods -n <platform-system-namespace> -o wide
kubectl get deploy,sts,ds,svc -n <platform-system-namespace>
kubectl get crd | grep -E 'external-secrets|kafka|coherence|opentelemetry|database|clickhouse'
kubectl get events -n <platform-system-namespace> --sort-by=.lastTimestamp
```

Expected prerequisite components, when enabled:

- cert-manager
- External Secrets Operator
- metrics-server
- kube-state-metrics
- Strimzi Kafka Operator
- Coherence Operator
- OpenTelemetry Operator
- Oracle Database Operator
- ClickHouse CRDs

### 6. Install OBaaS

Install OBaaS in the application namespace:

```bash
helm upgrade --install <app-release> helm/infra-charts/obaas \
  -n <application-namespace> \
  --create-namespace \
  -f <app-values-file>
```

Verify:

```bash
helm status <app-release> -n <application-namespace>
kubectl get pods -n <application-namespace> -o wide
kubectl get deploy,sts,svc,ingress,gateway,httproute,pvc,job -n <application-namespace>
kubectl get instrumentation traces-instrumentation -n <application-namespace>
kubectl get events -n <application-namespace> --sort-by=.lastTimestamp
```

Expected OBaaS components, when enabled:

- APISIX gateway and admin service
- Envoy Gateway or ingress-nginx, according to `<access-path>`
- Eureka
- Config Server
- Spring Boot Admin Server
- SigNoz
- ClickHouse
- Oracle Database Exporter
- OTMM/MicroTx
- Oracle database integration or in-cluster database resources
- Kafka resources, if enabled
- AI Optimizer, if enabled
- OTMM workflow server or console, if enabled

Do not deploy CloudBank until all required OBaaS components are healthy.

## CloudBank Deployment

CloudBank v5 must be installed in the same namespace as OBaaS.

### 1. CloudBank Preflight

Run from the repository root unless a step changes directory:

```bash
kubectl get secret <priv-secret-name> -n <application-namespace>
kubectl get instrumentation traces-instrumentation -n <application-namespace>
cd cloudbank-v5
./check_prereqs.sh --build
./check_prereqs.sh --deploy \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname> \
  -s <priv-secret-name>
```

If `<priv-secret-name>` is the default `<cloudbank-dbname>-db-priv-authn`, the `-s` argument may be omitted.

Expected:

- Build and deploy prerequisites pass.
- Privileged DB secret exists.
- `traces-instrumentation` exists when observability and Java auto-instrumentation are enabled.

### 2. Build And Publish Images

For OCI/OCIR auto-detection:

```bash
cd cloudbank-v5
./1-oci_repos.sh -c <compartment-name> -p <prefix>
./2-images_build_push.sh -p <prefix> -t <cloudbank-image-tag> --yes
```

For an explicit registry:

```bash
cd cloudbank-v5
./2-images_build_push.sh \
  -r <cloudbank-registry> \
  -t <cloudbank-image-tag> \
  --yes
```

For local clusters where images are already available to the cluster runtime:

```bash
cd cloudbank-v5
./2-images_build_push.sh --skip-push --yes
```

Expected:

- Images build for `azn-server`, `account`, `customer`, `creditscore`, `transfer`, `checks`, and `testrunner`.
- Image push or local availability is proven.

### 3. Create CloudBank Secrets

```bash
cd cloudbank-v5
./3-k8s_db_secrets.sh \
  -n <application-namespace> \
  -d <cloudbank-dbname> \
  -s <priv-secret-name>
```

Expected:

- CloudBank DB secrets exist.
- `<cloudbank-dbname>-azn-server-auth` exists with OAuth client secret keys.
- `<cloudbank-dbname>-azn-server-signing-key` exists.

### 4. Deploy CloudBank Services

For OCI/OCIR auto-detection:

```bash
cd cloudbank-v5
./4-deploy_all_services.sh \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname> \
  -s <priv-secret-name> \
  -p <prefix> \
  -t <cloudbank-image-tag> \
  --yes
```

For an explicit registry:

```bash
cd cloudbank-v5
./4-deploy_all_services.sh \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname> \
  -s <priv-secret-name> \
  -r <cloudbank-registry> \
  -t <cloudbank-image-tag> \
  --image-pull-secret <image-pull-secret> \
  --yes
```

Omit `--image-pull-secret` when the cluster can pull images anonymously.

Verify:

```bash
helm list -n <application-namespace>
kubectl get pods -n <application-namespace> \
  | grep -E 'azn-server|account|customer|creditscore|transfer|checks|testrunner'
kubectl get jobs -n <application-namespace> | grep db-init
```

Expected: all seven CloudBank service pods are `1/1 Running`, and database init jobs succeed.

### 5. Create APISIX Routes

```bash
cd cloudbank-v5
./5-apisix_create_routes.sh \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname>
```

Expected:

- Public authorization routes exist for `/.well-known/*` and `/oauth2/*`.
- Protected CloudBank API routes exist.
- `/user/api/v1*` is not externally exposed.
- Internal account journal routes are blocked externally.

### 6. Smoke Test

```bash
cd cloudbank-v5
./6-smoke_test_secure_services.sh \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname>
```

If an external gateway URL is supplied:

```bash
cd cloudbank-v5
./6-smoke_test_secure_services.sh \
  -n <application-namespace> \
  -o <app-release> \
  -d <cloudbank-dbname> \
  --gateway-url <gateway-url>
```

Expected:

- Authorization metadata and JWKS are reachable.
- Protected API without token returns `401`.
- Protected API with correct read token returns success.
- Wrong-scope calls return `403`.
- Deposit and transfer checks succeed unless `--read-only` is used.

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

## Functional Test Details

### APISIX Gateway

Find the gateway:

```bash
kubectl get svc -n <application-namespace> | grep apisix-gateway
```

For local testing:

```bash
kubectl port-forward -n <application-namespace> svc/<app-release>-apisix-gateway 9080:80
export GATEWAY_URL=http://127.0.0.1:9080
```

For external testing:

```bash
export GATEWAY_URL=<https-gateway-url>
```

Use HTTPS for external gateway URLs so client secrets and tokens are not sent over plaintext network links.

### APISIX Admin API

```bash
kubectl port-forward -n <application-namespace> svc/<app-release>-apisix-admin 9180:9180
APISIX_KEY=$(
  kubectl -n <application-namespace> get configmap <app-release>-apisix \
    -o jsonpath='{.data.config\.yaml}' \
    | grep -A2 'name.*admin' \
    | grep key \
    | awk '{print $2}'
)
curl -s http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $APISIX_KEY" | jq
```

Expected: APISIX returns route data, including CloudBank routes after `5-apisix_create_routes.sh`.

### Eureka

```bash
kubectl port-forward -n <application-namespace> svc/<app-release>-eureka 8761:8761
curl -s http://127.0.0.1:8761/eureka/apps | tee "$EVIDENCE_DIR/obaas/eureka-apps.xml"
```

Expected after CloudBank deployment:

- `AZN-SERVER`
- `ACCOUNT`
- `CUSTOMER`
- `CREDITSCORE`
- `TRANSFER`
- `CHECKS`
- `TESTRUNNER`

Capture a Selenium screenshot of `http://127.0.0.1:8761`.

### Config Server

```bash
kubectl port-forward -n <application-namespace> svc/<app-release>-config-server 8081:8080
curl -s http://127.0.0.1:8081/application/default | jq
```

Expected: JSON response from Spring Cloud Config Server. If no property sources are configured, an empty `propertySources` array is acceptable only when Config Server reachability is proven and the report records that no test property was seeded.

When the run scope includes config data validation, seed a test property using the documented SQLcl pod approach from `docs-source/site/docs/platform/configserver.md`, then verify:

```bash
curl -s http://127.0.0.1:8081/billing/default/latest | jq
```

Expected: the response includes the seeded property values.

### Spring Boot Admin

```bash
kubectl port-forward -n <application-namespace> svc/<app-release>-admin-server 8989:8989
```

Capture a Selenium screenshot of `http://127.0.0.1:8989`.

Expected:

- UI is reachable.
- Registered CloudBank Spring Boot services appear after deployment.
- Health status is available for each registered service.

### CloudBank OAuth And APIs

```bash
export CLIENT_ID=cloudbank-client
export CLIENT_SECRET=$(
  kubectl get secret <cloudbank-dbname>-azn-server-auth -n <application-namespace> \
    -o jsonpath='{.data.client-secret}' | base64 -d
)
export TEST_CLIENT_ID=cloudbank-test-client
export TEST_CLIENT_SECRET=$(
  kubectl get secret <cloudbank-dbname>-azn-server-auth -n <application-namespace> \
    -o jsonpath='{.data.test-client-secret}' | base64 -d
)

curl -s "$GATEWAY_URL/.well-known/oauth-authorization-server" | jq
curl -s "$GATEWAY_URL/oauth2/jwks" | jq '.keys[].kid'

export READ_TOKEN=$(
  curl -s -u "$CLIENT_ID:$CLIENT_SECRET" \
    -X POST "$GATEWAY_URL/oauth2/token" \
    -d grant_type=client_credentials \
    -d scope=cloudbank.read | jq -r .access_token
)
export WRITE_TOKEN=$(
  curl -s -u "$CLIENT_ID:$CLIENT_SECRET" \
    -X POST "$GATEWAY_URL/oauth2/token" \
    -d grant_type=client_credentials \
    -d scope="cloudbank.read cloudbank.write" | jq -r .access_token
)
export TEST_TOKEN=$(
  curl -s -u "$TEST_CLIENT_ID:$TEST_CLIENT_SECRET" \
    -X POST "$GATEWAY_URL/oauth2/token" \
    -d grant_type=client_credentials \
    -d scope=cloudbank.test | jq -r .access_token
)
export TRANSFER_TOKEN=$(
  curl -s -u "$CLIENT_ID:$CLIENT_SECRET" \
    -X POST "$GATEWAY_URL/oauth2/token" \
    -d grant_type=client_credentials \
    -d scope=cloudbank.transfer | jq -r .access_token
)
```

Core checks:

```bash
curl -i "$GATEWAY_URL/api/v1/creditscore"
curl -s -H "Authorization: Bearer $READ_TOKEN" "$GATEWAY_URL/api/v1/accounts" | jq
curl -s -H "Authorization: Bearer $READ_TOKEN" "$GATEWAY_URL/api/v1/customer" | jq
curl -s -H "Authorization: Bearer $READ_TOKEN" "$GATEWAY_URL/api/v1/creditscore" | jq
```

Deposit and transfer checks:

```bash
export FROM_ACCOUNT_ID=<account-id-with-positive-balance>
export TO_ACCOUNT_ID=<another-account-id>

curl -i -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d "{\"accountId\": ${TO_ACCOUNT_ID}, \"amount\": 256}" \
  "$GATEWAY_URL/api/v1/testrunner/deposit"

curl -i -H "Authorization: Bearer $READ_TOKEN" \
  "$GATEWAY_URL/api/v1/account/${TO_ACCOUNT_ID}/journal"

curl -i -X POST -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"journalId": <journal-id>}' \
  "$GATEWAY_URL/api/v1/testrunner/clear"

curl -s -H "Authorization: Bearer $READ_TOKEN" \
  "$GATEWAY_URL/api/v1/account/${TO_ACCOUNT_ID}" | jq
curl -s -H "Authorization: Bearer $READ_TOKEN" \
  "$GATEWAY_URL/api/v1/account/${FROM_ACCOUNT_ID}" | jq
curl -s -X POST -H "Authorization: Bearer $TRANSFER_TOKEN" \
  "$GATEWAY_URL/transfer?fromAccount=${FROM_ACCOUNT_ID}&toAccount=${TO_ACCOUNT_ID}&amount=100"
curl -s -H "Authorization: Bearer $READ_TOKEN" \
  "$GATEWAY_URL/api/v1/account/${TO_ACCOUNT_ID}" | jq
curl -s -H "Authorization: Bearer $READ_TOKEN" \
  "$GATEWAY_URL/api/v1/account/${FROM_ACCOUNT_ID}" | jq
```

Expected:

- Missing token returns `401`.
- Wrong scope returns `403`.
- Read APIs return valid JSON.
- Deposit returns success and creates a pending journal entry.
- Clearance changes the journal to a completed deposit.
- Transfer response contains `withdraw succeeded deposit succeeded`.
- Source and destination balances change by the transfer amount.

Capture logs:

```bash
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=checks
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=transfer
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=azn-server
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=account
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=customer
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=creditscore
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=testrunner
```

## Observability Test Requirements

The PDF checklist is an image-only SigNoz Enterprise Services screenshot. It requires evidence that SigNoz Services displays active services over a recent time window and that the Services table has populated `P99 latency (in ms)`, `Error Rate (% of total)`, and `Operations Per Second` columns. Treat this as an explicit acceptance item.

### Access SigNoz

```bash
kubectl -n <application-namespace> get secret signoz-authn \
  -o jsonpath='{.data.email}' | base64 -d && echo
kubectl -n <application-namespace> get secret signoz-authn \
  -o jsonpath='{.data.password}' | base64 -d && echo
kubectl -n <application-namespace> port-forward svc/<app-release>-signoz 8080:8080
```

Open `http://127.0.0.1:8080/login` and capture screenshots after login.

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
2. Uninstall OBaaS:

```bash
helm uninstall <app-release> -n <application-namespace>
kubectl get all,secret,configmap,pvc,job,ingress,gateway,httproute -n <application-namespace>
```

3. Verify the namespace is empty except for explicitly retained or approved resources.
4. Reinstall OBaaS into the same namespace using the same values.
5. Rerun platform and CloudBank smoke tests.

### Multi-OBaaS

Install a second OBaaS instance in a different namespace:

```bash
helm upgrade --install <tenant2-release> helm/infra-charts/obaas \
  -n <tenant2-namespace> \
  --create-namespace \
  -f <tenant2-values-file>
```

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

When any test fails, immediately collect:

```bash
kubectl get pods -n <application-namespace> -o wide
kubectl get jobs -n <application-namespace>
kubectl get events -n <application-namespace> --sort-by=.lastTimestamp
helm status <app-release> -n <application-namespace>
```

For each failing pod:

```bash
kubectl describe pod <pod> -n <application-namespace>
kubectl logs <pod> -n <application-namespace>
kubectl logs <pod> -n <application-namespace> --previous
```

For failed database initialization:

```bash
kubectl logs job/<service>-db-init -n <application-namespace>
kubectl get secrets -n <application-namespace> | grep -E 'db-authn|azn-server'
```

For route or authorization failures:

```bash
kubectl get configmap <app-release>-apisix -n <application-namespace>
kubectl get svc -n <application-namespace> | grep apisix
curl -s http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $APISIX_KEY" | jq
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=azn-server
```

For observability failures:

```bash
kubectl get pods,svc,endpoints -n <application-namespace> | grep -E 'signoz|clickhouse|otel|k8s-infra'
kubectl logs -n <application-namespace> -l app.kubernetes.io/name=<app-release>
kubectl get instrumentation traces-instrumentation -n <application-namespace> -o yaml
kubectl get pods -n <application-namespace> -o yaml | grep -A5 -B5 OTEL_EXPORTER_OTLP_ENDPOINT
```

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
