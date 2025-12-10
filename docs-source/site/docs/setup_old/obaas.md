---
title: Prepare and Install the OBaaS Helm chart
sidebar_position: 10
---
## OBaaS Helm Chart Installation Guide

## Overview

This guide walks you through preparing and installing the OBaaS Helm chart in your Kubernetes cluster.

## Prerequisites

Navigate to the `obaas` directory containing the Helm chart files:

```bash
cd obaas/
ls
```

Expected output:

```text
Chart.yaml  LICENSE  README.md  crds  templates  values.yaml
```

## Configuration

### Editing values.yaml

Before installation, you must edit the `values.yaml` file according to your environment requirements.

#### Private Repository Configuration

If you are using a private repository, update each `image` entry to point to your private repository instead of the public repositories.

#### Component Selection (Optional)

Each component (e.g., apisix, kafka, coherence) has an `enabled: true` entry. To omit a component, change the setting to `false`.

#### Namespace Configuration (Optional)

To install components into separate namespaces, override the global namespace by setting a value in the `namespace` property inside the component's section.

#### Database Configuration (Optional)

To use an existing Oracle database in your applications, set `database.enabled` to `true` and configure one of the following options:

##### Option 1: Oracle Autonomous Database (ADB-S)

Use this option if your database is an Oracle Autonomous Database in OCI and you want Oracle Database Operator to access and create `tns` and `wallet` secrets.

Configure the following settings:

- Set `database.type` to `"ADB-S"`
- Provide the OCID of your ADB-S instance in `database.oci_db.ocid`
- Update the `database.oci_config` section:
  - Set `oke` to `false` (setting this to `true` is not supported in version 2.0.0-M4)
  - Supply your `tenancy`, `user ocid`, `fingerprint`, and `region` (these must match the details provided when creating the OCI configuration secret)

##### Option 2: Non-ADB or Manual Configuration

Use this option if your database is not an Oracle Autonomous Database in OCI, or you do not want Oracle Database Operator to create the `tns` secret.

Configure the following settings:

- Modify or create the [Database Credentials Secret](./secrets.md#database-credentials-secret) to include `dbhost` and `dbport` for the database instance
- Leave `database.type` blank

> **Important**: Double-check all values before proceeding. Incorrect values will cause the OBaaS provisioning to fail.

## Installation

### Single Instance Installation

Install the Helm chart using the following command:

```bash
helm --debug install obaas \
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
I0817 13:21:41.363368 5981 warnings.go:110] "Warning: unknown field "spec.serviceName""
I0817 13:21:41.439521 5981 warnings.go:110] "Warning: unknown field "spec.serviceName""
I0817 13:21:41.439531 5981 warnings.go:110] "Warning: unknown field "spec.serviceName""
NAME: obaas
LAST DEPLOYED: Sun Aug 17 13:21:15 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

> **Note**: You may see warnings as shown above. These can be safely ignored in version 2.0.0-M4.

### Multiple Instance Installation

When installing multiple OBaaS instances in your cluster, each instance must have unique values for:

- `Release name`
- `obaasName`
- `targetNamespace`

**Example for development instance:**

```bash
helm --debug install obaas \
  --set global.obaasName="obaas-dev" \
  --set global.targetNamespace="obaas-dev" \
  ./
```

**Example for production instance:**

```bash
helm --debug install obaas-prod \
  --set global.obaasName="obaas-prod" \
  --set global.targetNamespace="obaas-prod" \
  ./
```

> **Important**: If you install APISIX in multiple instances, you must set different host names and/or ports for each APISIX ingress.

## Verification

### Verify Namespaces

Check that the namespaces have been created:

```bash
kubectl get ns
```

**Expected output (with component namespace overrides):**

```text
NAME                               STATUS   AGE
admin-server                       Active   32s
apisix                             Active   32s
application                        Active   32s
azn-server                         Active   32s
cert-manager                       Active   33m
coherence                          Active   32s
conductor-server                   Active   32s
config-server                      Active   32s
default                            Active   107m
eureka                             Active   32s
external-secrets                   Active   33m
ingress-nginx                      Active   34m
kafka                              Active   32s
kube-node-lease                    Active   107m
kube-public                        Active   107m
kube-state-metrics                 Active   33m
kube-system                        Active   107m
metrics-server                     Active   33m
obaas-admin                        Active   32s
observability                      Active   22m
oracle-database-exporter           Active   32s
oracle-database-operator-system    Active   12m
otmm                               Active   32s
```

If you did not override component namespaces, all pods will be in the target namespace (e.g., `obaas-dev`).

### Verify Pods

Check the status of all pods:

```bash
kubectl get pod -A
```

> **Note**: It takes approximately 5 minutes for all pods to reach ready/running status.

## Troubleshooting

If the installation fails, verify the following:

1. All values in `values.yaml` are correct
1. Database credentials and connection information are accurate
1. OCI configuration (if using ADB-S) matches the secret created earlier
1. For multiple instances, ensure unique `Release name`s, `obaasName`, and `targetNamespace` values
1. For multiple APISIX instances, verify different host names and/or ports are configured
