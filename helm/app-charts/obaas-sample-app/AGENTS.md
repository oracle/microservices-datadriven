# Repository Guidelines

## Project Structure & Module Organization

This repository directory contains the `obaas-sample-app` Helm chart for deploying Spring Boot or Helidon services to OBaaS. `Chart.yaml` holds chart metadata and versioning. `values.yaml` defines the public configuration surface, including required `image`, `obaas`, and `database` values. Kubernetes manifests live in `templates/`; shared template helpers are in `templates/_helpers.tpl`, install notes are in `templates/NOTES.txt`, and the Helm test hook is `templates/tests/test-connection.yaml`. Example manifests belong in `examples/`, such as `examples/sqlcl-pod.yaml`.

## Build, Test, and Development Commands

Run commands from this chart root.

```bash
helm lint .
```

Validates chart metadata, values, and template syntax.

```bash
helm template my-app . -f values.yaml --namespace my-namespace
```

Renders manifests locally for review. Use an override file with real required values when `values.yaml` keeps placeholders empty.

```bash
helm install my-app . -f my-values.yaml -n my-namespace
helm upgrade my-app . -f my-values.yaml -n my-namespace
```

Installs or upgrades the chart against a Kubernetes cluster.

```bash
helm test my-app -n my-namespace
```

Runs the chart test pod after installation.

## Coding Style & Naming Conventions

Use two-space indentation in YAML and Helm templates. Keep values lower camelCase where existing keys use it, for example `releaseName`, `imagePullSecrets`, and `serviceAccount`. Resource names should be derived through helpers in `templates/_helpers.tpl` rather than duplicated inline. Keep comments in `values.yaml` actionable and focused on user-facing configuration.

## Testing Guidelines

At minimum, run `helm lint .` and `helm template` before opening a PR. When changing install behavior, render with representative Spring Boot and Helidon overrides to verify framework-specific environment variables, probes, and service discovery settings. For cluster-facing changes, install into a disposable namespace and run `helm test`.

## Commit & Pull Request Guidelines

Recent history uses short imperative or descriptive subjects, often followed by a PR number, such as `Fix broken links (#1312)` or `Added helidon-producer with Reactive Messaging and OTEL Observability (#1308)`. Keep commits focused on one chart concern. Pull requests should explain the changed chart behavior, list validation commands run, link related issues, and include rendered manifest snippets when templates or default values change.

## Security & Configuration Tips

Do not commit real database credentials, wallet contents, or tenant-specific image pull secrets. Document secret names and keys instead, following the existing `database.authN` and `database.privAuthN` patterns in `values.yaml` and `README.md`.
