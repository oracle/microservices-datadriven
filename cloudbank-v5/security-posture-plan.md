# CloudBank v5 Security Posture Plan

## Summary

- Add an Oracle-backed Spring Authorization Server as a new CloudBank service named `azn-server`, using the Boot 3 branch of the reference implementation: https://github.com/markxnelson/azn-server/tree/SPRING_BOOT_3.X.
- Keep every implementation change under `cloudbank-v5`; do not modify shared Helm charts, OBaaS infrastructure charts, or any files outside this directory.
- Secure only the deployed Spring services in this round: `account`, `customer`, `creditscore`, `transfer`, `checks`, and `testrunner`.
- Do not touch Helidon services. Do not bring `chatbot` into the secured/deployed service set unless a later request explicitly expands scope.
- Use service-side Spring Security resource-server enforcement out of the box as the hard boundary. Also update APISIX routes to add authentication or token-forwarding plugins where appropriate, using `endpoint-authorization-matrix.md` as the route policy input.
- Move all in-scope Java services to the current OBaaS 2.1.0 observability model: OpenTelemetry Java agent auto-injection through the OBaaS application chart, not application-packaged OpenTelemetry SDK/starter dependencies.

## Key Changes

- Update CloudBank's Spring baseline to match the Boot 3 azn-server branch: Spring Boot `3.5.14` and Spring Cloud `2025.0.2`, unless implementation testing finds a specific blocking incompatibility that must be documented.
- Add `cloudbank-v5/azn-server` as a Maven module based on the `SPRING_BOOT_3.X` azn-server code, with CloudBank-compatible package/import style, JKube image build configuration, OBaaS sample-app Helm values, Eureka registration, actuator/prometheus exposure, Oracle UCP/wallet configuration, and Liquibase schema setup.
- Migrate observability from the old app-managed model to the new Java instrumentation injection model documented under OBaaS `next`:
  - use `otel.enabled: true` in each in-scope Spring service values file, including the new `azn-server`, so the app chart adds `instrumentation.opentelemetry.io/inject-java`;
  - rely on the platform `traces-instrumentation` resource and OBaaS/SigNoz collector configuration for Java agent injection and OTLP export;
  - keep Spring Boot Actuator and Prometheus registry only where needed for `/actuator/prometheus` scraping;
  - remove application-packaged tracing/exporter/instrumentation dependencies from CloudBank's parent and service POMs, including `micrometer-tracing-bridge-otel`, `micrometer-tracing`, `opentelemetry-exporter-otlp`, `opentelemetry-spring-boot-starter`, `opentelemetry-oracle-ucp-11.2`, the OpenTelemetry instrumentation BOM, and datasource-micrometer dependencies/config unless a non-observability runtime dependency requires them;
  - remove old application-level OTEL exporter/tracing configuration and custom SDK assumptions from `common.yaml`;
  - do not change Helidon service observability in this round.
- Add `azn-server` database/bootstrap secrets to `3-k8s_db_secrets.sh`. Include generated or provided values for:
  - `AZN_USER_REPO_PASSWORD`
  - `ORACTL_ADMIN_PASSWORD`
  - `ORACTL_USER_PASSWORD`
  - default OAuth client secret for `cloudbank-client`
- Harden secret handling in `3-k8s_db_secrets.sh`:
  - do not print generated plaintext passwords by default;
  - print retrieval commands and secret names instead;
  - if plaintext display is still useful for demos, require an explicit opt-in flag such as `--show-passwords` and document that it is unsafe for shared terminals/logs.
- Add Spring Security resource-server support through the shared `common` module so each in-scope service validates JWT bearer tokens from `azn-server`.
- Use `endpoint-authorization-matrix.md` as the source of truth for endpoint-to-scope mapping. Implement concrete Spring Security matchers for the listed CloudBank API paths and the listed LRA/internal callback paths rather than relying on broad wildcard exemptions.
- Update APISIX route definitions to reflect the endpoint authorization matrix:
  - keep public auth-server metadata/JWK routes unauthenticated;
  - require authentication on externally exposed CloudBank API routes where the backend requires `cloudbank.*` scopes;
  - avoid externally routing internal-only endpoints such as service-to-service, JMS-driven, and LRA callback paths unless a route is explicitly required;
  - preserve and forward the `Authorization` header to backend services so Spring Security can perform final JWT validation;
  - keep APISIX OpenTelemetry/Prometheus plugins on routes as they are today unless they conflict with authentication.
- Permit only the minimum anonymous endpoints needed for operations and compatibility:
  - `/actuator/health`
  - `/actuator/info`
  - `/actuator/prometheus`
  - `/error`
  - MicroTx/LRA callback endpoints required by the existing transfer workflow
- Configure OAuth2 client-credentials propagation for internal service calls:
  - `checks` Feign calls to `account`
  - `transfer` RestTemplate calls to `account` and `transfer`
- Update CloudBank scripts only:
  - `1-oci_repos.sh`: include an `azn-server` image repository when the script creates or verifies service repositories.
  - `2-images_build_push.sh`: add `azn-server` to the Spring image build list.
  - `3-k8s_db_secrets.sh`: create or document required azn-server runtime, Liquibase/bootstrap, and OAuth client secrets alongside the existing service database secrets.
  - `4-deploy_all_services.sh`: deploy `azn-server` before secured services and pass auth-related environment values.
  - `5-apisix_create_routes.sh`: add auth-server routes for `/.well-known/*`, `/oauth2/*`, and `/user/api/v1*`, and add APISIX authentication/token-forwarding plugin configuration to CloudBank routes as required by `endpoint-authorization-matrix.md`.
  - `check_prereqs.sh`: update prerequisite checks if new auth-server, token, or observability validation needs reusable helper functions.
- Update CloudBank values files only:
  - Add `azn-server/values.yaml`.
  - Add resource-server issuer/JWK configuration to in-scope service values through `env`.
  - Add non-root `securityContext` / `podSecurityContext` entries for the Spring services where the shared sample chart already supports them.
- Fix or explicitly account for non-root container findings:
  - prefer adding JKube configuration under `cloudbank-v5` so generated Spring service Dockerfiles include a non-root `USER` directive;
  - if the shared base image or JKube generation makes this impractical without leaving `cloudbank-v5`, keep runtime `securityContext` hardening and document the residual generated-Dockerfile Trivy finding as accepted for this pass.
- Tighten shared runtime defaults in `common.yaml`:
  - expose only needed actuator endpoints;
  - avoid public health details;
  - disable env info exposure;
  - disable request payload/header logging by default;
  - disable JDBC parameter-value logging by default.
- Document that OBaaS 2.1.0-build.12 requires CloudBank to use the new Java instrumentation auto-injection path for successful installation and operation; the older dependency/configuration-heavy observability instructions are no longer the target for these services.

## Scanner Findings To Address

- Trivy was run against `cloudbank-v5` with HIGH/CRITICAL vulnerability, secret, and misconfiguration scanners.
- Initial CloudBank dependency findings were resolved by moving to the Spring Boot 3.5 line, removing old application-managed OpenTelemetry dependencies, overriding Bouncycastle to `1.84`, overriding Netty to `4.1.133.Final`, and excluding unused native epoll from the MicroTx path.
- Current Trivy rerun shows zero HIGH/CRITICAL vulnerability findings and zero secret findings.
- Current remaining Trivy findings are HIGH `DS-0002` non-root-user findings in generated Spring service Dockerfiles under `target/`, the generated parent Dockerfile under `target/`, and Helidon manual Dockerfiles.
- Helidon Dockerfile findings are out of scope for this round. Generated Spring Dockerfile findings are not edited directly; the in-scope Spring services now set non-root runtime `podSecurityContext` and container `securityContext` values through CloudBank Helm values.

## Tests And Verification

- Run Maven tests for the updated parent, `common`, `azn-server`, and the six secured Spring services.
- Add or update tests proving:
  - unauthenticated protected API calls return `401`;
  - valid bearer tokens from `azn-server` allow expected API calls;
  - actuator health/info/prometheus remain reachable as intended;
  - `checks` can still call `account`;
  - `transfer` can still complete and compensate its workflow;
  - `azn-server` exposes metadata, JWKs, and token issuance.
- Run deployment dry-runs:
  - `1-oci_repos.sh --dry-run` or equivalent output includes `azn-server` when repositories are managed;
  - `2-images_build_push.sh --skip-push` or dry-run-equivalent verification includes `azn-server`;
  - `3-k8s_db_secrets.sh --dry-run` shows the new azn-server-related secrets without exposing real credentials in committed files;
  - `4-deploy_all_services.sh --dry-run` deploys `azn-server` before resource-server services and passes auth/observability env values;
  - `5-apisix_create_routes.sh --dry-run` includes auth-server routes, existing CloudBank routes, and the expected APISIX authentication/token-forwarding plugin configuration;
  - image build list includes `azn-server`;
  - service deployment includes seven Spring services total;
  - rendered Spring service pods include the Java auto-injection annotation when `otel.enabled: true`;
  - APISIX dry-run proves public routes remain public, protected routes include auth configuration, and internal-only paths are not exposed unexpectedly.
- Verify observability migration:
  - `rg` and/or Maven dependency output no longer show removed app-managed OpenTelemetry tracing/exporter/instrumentation dependencies in in-scope Spring services;
  - `common.yaml` no longer configures SDK/exporter behavior that belongs to the injected Java agent;
  - rendered `azn-server` and Spring application pods have `otel.enabled: true` behavior and the Java auto-injection annotation;
  - docs explain that Java telemetry is supplied by OBaaS auto-injection and that agent tuning belongs in the OBaaS `signoz.instrumentation.java.env` values path, not in individual app POMs.
- Verify authorization policy:
  - protected endpoints listed in `endpoint-authorization-matrix.md` reject requests without a bearer token;
  - protected endpoints reject tokens missing the required scope;
  - public auth-server metadata/JWK endpoints remain reachable without a token;
  - internal-only/LRA paths are not externally routed unless deliberately documented.
- Run Trivy before and after implementation:
  - `trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed cloudbank-v5`
  - assess this round with Helidon directories excluded from acceptance.
  - specifically verify whether generated Spring service Dockerfiles still report DS-0002 and document any residual acceptance.
- Update `README.md`, `cloudbank-v5-install.md`, and `cloudbank-test-doc.md` so out-of-box usage shows the new secure install flow, the new azn-server service, the token acquisition step, secured API curl examples, and the new OBaaS Java instrumentation model.
- In `cloudbank-v5-install.md`, update every step that refers to top-level shell scripts so the documented workflow matches script behavior:
  - repository creation includes `azn-server`;
  - image build/push includes `azn-server`;
  - database/secret preparation includes azn-server and OAuth client secrets;
  - service deployment order installs `azn-server` before protected services;
  - APISIX route creation includes authorization-server endpoints and authentication configuration for protected CloudBank routes;
  - verification commands use bearer tokens for protected CloudBank APIs;
  - observability notes explain that OBaaS 2.1.0-build.12 uses Java agent auto-injection instead of application-packaged OpenTelemetry dependencies.
  - cleanup/uninstall, APISIX route deletion, troubleshooting, and verification sections include `azn-server`, its route IDs, and its expected secrets.

## Assumptions

- `azn-server` is the authorization server and issuer for CloudBank's sample deployment.
- The default sample OAuth client is named `cloudbank-client` and supports client credentials for automation and internal service calls.
- The default user/bootstrap setup is acceptable for sample/demo use; production hardening for persistent signing keys and external client registration storage is documented as follow-up unless the implementation can reuse an existing branch feature with minimal changes.
- APISIX authentication is a gateway hardening layer for externally exposed routes; service-side JWT validation remains the required security boundary for this pass.
- APISIX plugin selection must use what is available in the installed OBaaS 2.1.0-build.12 APISIX configuration. If a desired plugin is unavailable, preserve token forwarding and document the gap rather than weakening service-side enforcement.
