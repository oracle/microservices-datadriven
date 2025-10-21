---
title: Prepare and Install OBaaS Prerequisites Helm Chart
sidebar_position: 7
---
## Prepare and Install OBaaS Prerequisites Helm Chart

## Overview

The OBaaS Prerequisites chart contains cluster-level components that are shared across all OBaaS instances in your Kubernetes cluster. This chart must be installed once per cluster before installing any OBaaS instances.

## Prerequisites

Navigate to the `obaas-prereqs` directory containing the Helm chart files:

```bash
cd obaas-prereqs/
ls
```

Expected output:

```text
Chart.yaml  LICENSE  README.md  templates  values.yaml
```

## Configuration

### Editing values.yaml

Before installation, edit the `values.yaml` file according to your environment requirements.

#### Private Repository Configuration

If you are using a private repository, update each `image` entry to point to your private repository instead of the public repositories.

#### Component Selection (Optional)

Each component (e.g., kube-state-metrics, metrics-server, cert-manager) has an `enabled: true` entry. To omit a component, change the setting to `false`.

:::warning Component Dependencies
Note the following required components:

- **cert-manager**: Required for all installations
- **metrics-server**: Required if you plan to use Horizontal Pod Autoscaling (HPA)
:::

## Installation

### Install the Prerequisites Chart

Install the Helm chart using the following command:

```bash
helm --debug install obaas-prereqs ./
```

**Installation notes:**

- `obaas-prereqs` is the Helm `Release name`
- The `--debug` flag is optional and enables verbose output from Helm
- This chart is shared across all OBaaS instances in the cluster
- Do NOT set `obaasName` or `targetNamespace` for this chart

**Expected output:**

```log
NAME: obaas-prereqs
LAST DEPLOYED: Sun Aug 17 12:47:51 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

:::info Shared Resources
The prerequisites chart creates cluster-level resources shared by all OBaaS instances. It should only be installed once per cluster, and we recommend NOT setting instance-specific parameters like `obaasName` or `targetNamespace`.
:::

## Verification

### View Installed Charts

After installation completes, verify the chart was installed successfully:

```bash
helm ls
```

**Expected output:**

```text
NAME            NAMESPACE   REVISION    UPDATED                                 STATUS      CHART                       APP VERSION
obaas-prereqs   default     1           2025-09-12 13:37:16.026781 -0500 CDT    deployed    OBaaS-Prerequisites-0.0.1.  2.0.0-M4  
```

### Verify Namespaces

Check that the component namespaces have been created:

```bash
kubectl get ns
```

**Expected output (with component namespace overrides):**

```text
NAME                STATUS   AGE
cert-manager        Active   3m37s
default             Active   77m
external-secrets    Active   3m37s
ingress-nginx       Active   3m54s
kube-node-lease     Active   77m
kube-public         Active   77m
kube-state-metrics  Active   3m37s
kube-system         Active   77m
metrics-server      Active   3m37s
```

If you did not override component namespaces, all pods will be in the default namespace or your chosen target namespace.

### Verify Pods

Check that all prerequisite pods are running:

```bash
kubectl get pods -A
```

**Expected pods:**

```text
NAMESPACE            NAME                                                READY   STATUS    RESTARTS   AGE
cert-manager         cert-manager-7fbd576ffd-tzkmj                       1/1     Running   0          45s
cert-manager         cert-manager-cainjector-68f4656fdc-hfdw8            1/1     Running   0          45s
cert-manager         cert-manager-webhook-5cb89bf75b-h6sdr               1/1     Running   0          45s
external-secrets     external-secrets-6687559cc7-5xjbx                   1/1     Running   0          45s
external-secrets     external-secrets-cert-controller-79785cb877-fjd59   1/1     Running   0          45s
external-secrets     external-secrets-webhook-945df75bf-9zjqp            1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-j9bdk                      1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-splg7                      1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-x2wpz                      1/1     Running   0          45s
kube-state-metrics   kube-state-metrics-784bc85fd8-9fn5k                 1/1     Running   0          45s
metrics-server       metrics-server-77ff598cd8-b8nt8                     1/1     Running   0          45s
metrics-server       metrics-server-77ff598cd8-bnnld                     1/1     Running   0          45s
metrics-server       metrics-server-77ff598cd8-t6nx8                     1/1     Running   0          45s
```

:::note Pod Startup Time
It may take a few minutes for all pods to reach Running and Ready status. Monitor the pods until all show `1/1` in the READY column.
:::

### Monitor Pod Status

Watch pods as they start up:

```bash
kubectl get pods -A --watch
```

Press `Ctrl+C` to stop watching once all pods are running.

Alternatively, check specific namespaces:

```bash
kubectl get pods -n cert-manager
kubectl get pods -n external-secrets
kubectl get pods -n ingress-nginx
kubectl get pods -n metrics-server
kubectl get pods -n kube-state-metrics
```

## Installed Components

The prerequisites chart installs the following cluster-level components:

### Cert Manager

**Namespace:** `cert-manager`

Manages TLS certificates and certificate lifecycle automation.

**Pods:**

- `cert-manager`: Core certificate management
- `cert-manager-cainjector`: CA injection for webhooks
- `cert-manager-webhook`: Webhook for certificate validation

### External Secrets Operator

**Namespace:** `external-secrets`

Synchronizes secrets from external secret management systems.

**Pods:**

- `external-secrets`: Core operator
- `external-secrets-cert-controller`: Certificate management
- `external-secrets-webhook`: Webhook for validation

### Ingress NGINX

**Namespace:** `ingress-nginx`

Provides ingress controller for routing external traffic to services.

**Pods:**

- `ingress-nginx-controller`: One pod per worker node (DaemonSet)

### Metrics Server

**Namespace:** `metrics-server`

Collects resource metrics from Kubelets for autoscaling decisions.

**Pods:**

- `metrics-server`: Multiple replicas for high availability

### Kube State Metrics

**Namespace:** `kube-state-metrics`

Generates metrics about Kubernetes object states.

**Pods:**

- `kube-state-metrics`: Metrics collection service

## Troubleshooting

### Pods Not Starting

If pods fail to start or remain in pending state:

**Check pod events:**

```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Check pod logs:**

```bash
kubectl logs <pod-name> -n <namespace>
```

### Insufficient Resources

If pods are pending due to insufficient resources:

```bash
kubectl describe nodes
kubectl top nodes
```

Scale your cluster if needed to provide additional capacity.
