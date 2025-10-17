---
title: Create Namespace(s) for OBaaS
sidebar_position: 6
---
## Create Namespace(s) for OBaaS

## Overview

Each OBaaS instance requires its own dedicated namespace for isolation and organization within your Kubernetes cluster.

## Namespace Requirements

### Instance Isolation

Each OBaaS instance must be installed in its own unique namespace. This ensures:

- Resource isolation between instances
- Independent lifecycle management
- Clear separation of concerns
- Simplified troubleshooting and maintenance

### Prerequisites Chart Namespace

The `obaas-prereqs` chart has special considerations:

- Installed **once per cluster** (not per instance)
- Contains cluster-wide components shared by all OBaaS instances
- Should be installed in its own dedicated namespace, separate from OBaaS instances

:::info Multiple Instance Support
Multiple OBaaS instances are not supported in version 2.0.0-M4. This capability is planned for future releases.
:::

## Creating Namespaces

### Single Instance

For a single OBaaS installation, create one namespace:

```bash
kubectl create ns obaas-dev
```

Verify the namespace was created:

```bash
kubectl get ns obaas-dev
```

Expected output:

```text
NAME        STATUS   AGE
obaas-dev   Active   5s
```

### Multiple Instances (Future Support)

When multiple instances are supported, create a namespace for each instance. For example, to create development and production installations:

**Development namespace:**

```bash
kubectl create ns obaas-dev
```

**Production namespace:**

```bash
kubectl create ns obaas-prod
```

**Verify all namespaces:**

```bash
kubectl get ns | grep obaas
```

Expected output:

```text
obaas-dev    Active   10s
obaas-prod   Active   5s
```

## Namespace Naming Conventions

When naming your namespaces, consider the following best practices:

- Use lowercase letters, numbers, and hyphens only
- Keep names descriptive and meaningful (e.g., `obaas-dev`, `obaas-prod`, `obaas-staging`)
- Include environment indicators for clarity
- Avoid special characters or spaces
- Keep names concise but descriptive

**Examples of good namespace names:**

```bash
obaas-dev
obaas-production
obaas-test
obaas-staging
obaas-demo
```

## Verification

After creating namespaces, verify they exist and are active:

```bash
kubectl get namespaces
```

You should see your newly created OBaaS namespaces in the output with `Active` status.

## Troubleshooting

### Namespace Already Exists

If you receive an error that the namespace already exists:

```bash
kubectl get ns obaas-dev
```

If the namespace exists but you want to start fresh, delete it first:

```bash
kubectl delete ns obaas-dev
```

:::warning Data Loss
Deleting a namespace will remove all resources within it. Ensure you have backups if needed before deleting a namespace.
:::

### Namespace Stuck in Terminating State

If a namespace is stuck in "Terminating" state:

```bash
kubectl get ns obaas-dev
```

Check for resources preventing deletion:

```bash
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n obaas-dev
```
