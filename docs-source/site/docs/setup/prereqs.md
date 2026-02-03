---
title: Prerequisites
sidebar_position: 1
---

## Prerequisites for Oracle Backend for Microservices and AI (OBaaS) 2.0.0

## Overview

Before installing OBaaS, ensure your environment meets all prerequisites. Installing without meeting these requirements will result in deployment failures.

:::danger Critical
If your environment does not meet the prerequisites, the installation will fail. Do not proceed with installation until you have confirmed your environment meets all requirements.
:::

## System Requirements

### Kubernetes Cluster

A CNCF-compliant Kubernetes cluster with the following specifications:

**Cluster version:**

- Kubernetes 1.33.1 or compatible version

**Infrastructure requirements:**

- Minimum 3 worker nodes
- At least 2 OCPU and 32GB memory per worker node
- Working storage provider with storage class for RWX (ReadWriteMany) PVs

**Capacity planning:**

- Base configuration supports ONE OBaaS installation plus applications
- For TWO OBaaS instances: double the number of worker nodes
- Scale worker nodes based on additional application requirements

:::tip Recommended
Oracle Kubernetes Engine (OKE) "Quick Create/Enhanced" cluster is the recommended platform for OBaaS deployments.
:::

### Oracle Database

An Oracle Database instance with the following requirements:

**Database version:**

- Oracle AI Database 19c or later (minimum)
- Oracle AI Database 26ai (required for AI features)

**Recommended configuration:**

- Oracle AI Autonomous Database (ADB) 26ai ATP
- 2 ECPU
- 1TB storage
- Secure access from anywhere enabled

:::info AI Features
To use OBaaS AI capabilities, you must use Oracle Database 23ai. Earlier versions do not support AI features.
:::

### Private Image Repository (Optional)

If using a private container image repository:

**Requirements:**

- All OBaaS images copied to your private registry
- Registry credentials configured in Kubernetes
- Network access from cluster to private registry

**Helper script:**

OBaaS provides the `mirror-images.sh` script to assist with copying images to your private repository.

```bash
helm/tools/mirror-images.sh
```

## Verification

### Verify Kubernetes Cluster

Check your Kubernetes version:

```bash
kubectl version --short
```

Verify worker nodes meet requirements:

```bash
kubectl get nodes
kubectl describe nodes | grep -A 5 "Allocated resources"
```

Check storage classes:

```bash
kubectl get storageclass
```

Ensure you have a storage class that supports RWX (ReadWriteMany) access mode.

### Verify Default Namespaces

For a fresh OKE cluster, verify the default namespaces are present:

```bash
kubectl get ns
```

Expected output:

```
NAME            STATUS   AGE
default         Active   4m52s
kube-node-lease Active   4m52s
kube-public     Active   4m52s
kube-system     Active   4m52s
```
