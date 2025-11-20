---
title: Prepare and Install the OBaaS Observability Helm Chart
sidebar_position: 8
---
## Prepare and Install the OBaaS Observability Helm Chart

:::info Optional Component
This installation step is optional. The observability component provides monitoring and metrics capabilities but is not required for basic OBaaS functionality.
:::

## Overview

This guide provides instructions for preparing and installing the OBaaS Observability Helm chart, which enables monitoring and metrics collection for your OBaaS deployment.

## Prerequisites

Navigate to the `obaas-observability` directory containing the Helm chart files:

```bash
cd obaas-observability/
ls
```

Expected output:

```text
Chart.yaml  LICENSE  README.md  admin  dashboards  templates  values.yaml
```

## Configuration

### Editing values.yaml

Before installation, edit the `values.yaml` file according to your environment requirements.

#### Private Repository Configuration

If you are using a private repository, update each `image` entry to point to your private repository instead of the public repositories.

#### Namespace Configuration (Optional)

To install components into separate namespaces, override the global namespace by setting a value in the `namespace` property inside the component's section.

## Installation

### Single Instance Installation

Install the Helm chart using the following command:

```bash
helm upgrade --install --debug obaas-observability \
  --set global.obaasName="obaas-dev" \
  --set global.targetNamespace="obaas-dev" \
  ./
```

**Parameters:**

- `global.obaasName`: Sets the OBaaS instance name
- `global.targetNamespace`: Specifies the target namespace (optional, only needed to override the default namespace)
- `--debug`: Optional flag that enables verbose output from Helm

**Expected output:**

```log
NAME: obaas-observability
LAST DEPLOYED: Sun Aug 17 13:00:00 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

### Multiple Instance Installation

When installing multiple OBaaS instances in your cluster, each instance must have unique values for:

- `Release name`
- `obaasName`
- `targetNamespace`

**Example for development instance:**

```bash
helm upgrade --install --debug obaas-observability \
  --set global.obaasName="obaas-dev" \
  --set global.targetNamespace="obaas-dev" \
  ./
```

**Example for production instance:**

```bash
helm upgrade --install --debug obaas-prod-observability \
  --set global.obaasName="obaas-prod" \
  --set global.targetNamespace="obaas-prod" \
  ./
```

## Verification

:::note Namespace Configuration
Commands in this guide use `-n observability` as the default namespace for the observability components. If you overrode the namespace during installation, replace `observability` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep signoz
```
:::

### View Installed Charts

After installation completes, view the installed Helm charts:

```bash
helm ls
```

**Expected output:**

```text
NAME                NAMESPACE REVISION  UPDATED                               STATUS    CHART                     APP VERSION
obaas               default   1         2025-09-12 13:57:55.859836 -0500 CDT  deployed  OBaaS-0.0.1               2.0.0-M4   
obaas-db            default   1         2025-09-12 13:51:23.751199 -0500 CDT  deployed  OBaaS-db-0.1.0            2.0.0-M4   
obaas-observability default   1         2025-09-12 13:45:43.113298 -0500 CDT  deployed  OBaaS-observability-0.1.0 2.0.0-M4 
```

### Verify Pods

Check the pod status in your observability namespace, for example

```bash
kubectl get pods -n observability
```

:::note Pod Startup Time
It takes approximately 5 to 10 minutes for all observability pods to reach ready/running status. Please wait for all pods to be ready before continuing to the next step.
:::

### Monitor Pod Status

You can watch the pods as they start up:

```bash
kubectl get pods -n observability --watch
```

Press `Ctrl+C` to stop watching once all pods are running.

## Troubleshooting

If pods fail to start or remain in a pending state:

1. Check pod events in your observability namespace: `kubectl describe pod <pod-name> -n observability`
2. Review pod logs your observability namespace: `kubectl logs <pod-name> -n observability`
3. Verify resource availability: `kubectl top nodes`
4. Ensure all prerequisite charts are installed and healthy

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
