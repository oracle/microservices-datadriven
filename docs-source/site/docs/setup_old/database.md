---
title: Prepare and Install the OBaaS Database Helm Chart
sidebar_position: 9
---
## Prepare and Install the OBaaS Database Helm Chart

## Overview

This guide provides instructions for preparing and installing the OBaaS Database Helm chart in your Kubernetes cluster.

## Prerequisites

Navigate to the `obaas-db` directory containing the Helm chart files:

```bash
cd obaas-db/
ls
```

Expected output:

```text
Chart.yaml  scripts  templates  values.yaml
```

## Configuration

### Editing values.yaml

Before installation, edit the `values.yaml` file according to your environment requirements.

#### Private Repository Configuration

If you are using a private repository, update each `image` entry to point to your private repository instead of the public repositories.

#### Namespace Configuration (Optional)

To install components into separate namespaces, override the global namespace by setting a value in the `namespace` property inside the component's section.

:::warning Important
Double-check all values before proceeding. Incorrect values will cause the database provisioning to fail.
:::

## Installation

### Single Instance Installation

Install the Helm chart using the following command:

```bash
helm --debug install obaas-db \
  --set global.obaasName="obaas-dev" \
  --set global.targetNamespace="obaas-dev" \
  ./
```

**Parameters:**

- `global.obaasName`: Sets the OBaaS instance name
- `global.targetNamespace`: Specifies the target namespace (optional, only needed to override the default namespace)
- `--debug`: Optional flag that enables verbose output from Helm

**Expected output:**

```text
NAME: obaas-db
LAST DEPLOYED: Sun Aug 17 13:09:20 2025
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
helm --debug install obaas-db \
  --set global.obaasName="obaas-dev" \
  --set global.targetNamespace="obaas-dev" \
  ./
```

**Example for production instance:**

```bash
helm --debug install obaas-prod-db \
  --set global.obaasName="obaas-prod" \
  --set global.targetNamespace="obaas-prod" \
  ./
```

## Verification

### View Installed Charts

After installation completes, view the installed Helm charts:

```bash
helm ls
```

**Expected output:**

```text
NAME                NAMESPACE REVISION  UPDATED                               STATUS    CHART                     APP VERSION
obaas-db            default   1         2025-09-12 13:51:23.751199 -0500 CDT  deployed  OBaaS-db-0.1.0            2.0.0-M4   
obaas-observability default   1         2025-09-12 13:45:43.113298 -0500 CDT. deployed  OBaaS-observability-0.1.0 2.0.0-M4   
obaas-prereqs       default   1         2025-09-12 13:37:16.026781 -0500 CDT. deployed  OBaaS-Prerequisites-0.0.1 2.0.0-M4  
```

### Verify Pods and Namespaces

If you overrode the namespace for this component, you will see a new namespace (e.g., `oracle-database-operator-system`) with the following pods. Otherwise, the pods will be in your target namespace (e.g., `obaas-dev`).

```bash
kubectl get pods -n oracle-database-operator-system
```

![DB Operator pods](media/image6.png)
