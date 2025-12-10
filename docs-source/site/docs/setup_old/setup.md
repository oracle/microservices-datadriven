---
title: Introduction and Installation Flow
sidebar_position: 1
---
## Introduction and Installation Flow

:::danger Critical
The installation flow is **VERY** important. Follow each step thoroughly and in order. Do not proceed to the next step if you encounter issues. Resolve all problems before continuing.
:::

## Release Information

### Version 2.0.0-M4

Oracle Backend for Microservices and AI 2.0.0-M4 is an **internal-only** milestone release and is not available externally. This release represents a significant milestone on the path to version 2.0.0 and serves as a preview of upcoming capabilities.

:::info Milestone Release
This is a milestone release, not a finished product. You may encounter minor issues, which is expected. Please provide feedback to the development team if you encounter any problems.
:::

### What's New in 2.0.0-M4

This release introduces several key improvements over the previous production release (1.4.0):

**Installation Method:**

- Helm-based installation (replacing Ansible)
- Simplified deployment process
- Better integration with Kubernetes tooling

**Flexibility and Customization:**

- Select which components to install
- Customize namespaces for individual components
- Support for multiple OBaaS instances per cluster (with restrictions)

**Architecture Improvements:**

- Modular component design
- Better resource isolation
- Enhanced multi-tenancy support

### Known Limitations

Please be aware of the following known issues in this release:

**Oracle Cloud Infrastructure:**

- Instance principal authentication for OKE worker nodes may not work reliably in this release
- This limitation affects the Oracle Database Operator's ability to manage Autonomous Database instances

**Platform Support:**

- Tested and validated on Oracle Kubernetes Engine (OKE)
- Not tested on Oracle Cloud Native Environment (OCNE)

**Multi-Instance Installation:**

- Multiple OBaaS instances per cluster are supported but with restrictions

:::note Future Release
Version 2.0.0-M5 is planned for mid-October and will address these limitations.
:::

## Prerequisites

### Kubernetes Configuration

Before beginning installation, ensure your `kubectl` context is configured correctly:

**Set the kubeconfig:**

```bash
export KUBECONFIG=/path/to/your/kubeconfig
```

**Verify the correct cluster:**

```bash
kubectl cluster-info
kubectl get nodes
```

**Verify you have appropriate permissions:**

```bash
kubectl auth can-i create namespace
kubectl auth can-i create deployment
```

### Private Repository Setup (If Required)

If your environment does not have access to public container repositories, you must prepare a private repository before installation.

**Using the Helper Script:**

The installation package includes `private_repo_helper.sh` to assist with image management.

## Installation Flow

### Overview

The installation process consists of cluster-level setup followed by per-instance installation steps.

**Installation phases:**

**Phase 1: Cluster-Level Setup** (once per cluster)

1. Verify Prerequisites
2. Create Secrets
3. Create Namespaces
4. Install Prerequisites Chart

**Phase 2: Instance Installation** (repeat for each OBaaS instance)

1. Install Observability Chart (optional)
2. Install Database Chart
3. Install OBaaS Chart
4. Install CloudBank Sample (optional)

## Installation Best Practices

### Planning Your Deployment

**Single Instance:**

- Use descriptive namespace (e.g., `obaas-prod`, `obaas-dev`)
- Plan resource allocation based on expected workload
- Configure monitoring from the start

**Multiple Instances:**

- Plan namespace strategy upfront
- Ensure sufficient cluster resources for all instances
- Consider network policies for instance isolation
- Plan for shared vs. dedicated components

### Validation at Each Step

After each installation step:

- Verify all pods are running and ready
- Check logs for errors or warnings
- Test basic connectivity
- Confirm expected resources are created

### Troubleshooting During Installation

If you encounter issues:

1. **Stop and diagnose** - do not proceed to the next step
2. **Check pod status and logs** - identify the failing component
3. **Review configuration** - verify values.yaml settings
4. **Consult documentation** - refer to component-specific guides
5. **Seek assistance** - contact the development team with details
