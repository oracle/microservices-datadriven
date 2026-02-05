---
title: Helm Chart installation (manual)
sidebar_position: 2
---
## Oracle Backend for Microservices and AI (OBaaS) Helm Charts

This document describes how to deploy OBaaS to an existing Kubernetes cluster using Helm charts manually.

### What Gets Deployed

The OBaaS Helm charts deploy a complete microservices platform including:

**Prerequisites Chart** (cluster-scoped, install once):

- **cert-manager** - Automatic TLS certificate management
- **external-secrets** - Integration with external secret stores
- **metrics-server** - Container resource metrics
- **kube-state-metrics** - Kubernetes object metrics
- **strimzi-kafka-operator** - Kafka cluster operator
- **coherence-operator** - Distributed caching

**OBaaS Chart** (namespace-scoped, install per tenant):

- **ingress-nginx** - Namespace-specific ingress controller
- **Apache APISIX** - API Gateway
- **Eureka** - Service discovery
- **Signoz** - Observability stack with ClickHouse
- **Spring Boot Admin** - Application monitoring
- **Conductor** - Workflow orchestration
- **OTMM** - Transaction manager for microservices

### Prerequisites

:::warning Important
Ensure all prerequisites are met before starting the deployment.
:::

#### Required Tools

- **Helm**

  ```bash
  # Verify installation
  helm version
  ```

- **kubectl** - Configured with cluster access

  ```bash
  # Verify cluster access
  kubectl get nodes
  ```

#### Kubernetes Cluster Requirements

- **Kubernetes version**: 1.24 or later
- **Cluster resources**: Minimum requirements per OBaaS instance:
  - **CPU**: 8 cores available
  - **Memory**: 16 GB RAM available
  - **Storage**: Dynamic volume provisioning (StorageClass configured)
- **Network**: LoadBalancer service support (for ingress)
- **Permissions**: Cluster-admin access for prerequisites installation

#### Database Requirements

You must have access to an Oracle Database (19c or later):

- Autonomous Database (ADB-S or ADB-D)
- Oracle Database on-premise or cloud
- Connection details (host, port, service name)
- ADMIN or SYSTEM credentials for schema creation

### Directory Structure

```tree
helm/
├── obaas-prereqs/     # Cluster-singleton prerequisites (install once per cluster)
└── obaas/             # OBaaS application chart (install N times in different namespaces)
```

### Quick Start Guide

#### Step 1: Install Prerequisites (Once Per Cluster)

The prerequisites chart contains cluster-scoped singleton components that should only be installed once per cluster.

:::warning Cluster-Scoped Installation
Only install prerequisites once per cluster. Installing multiple times will cause conflicts with CRDs (Custom Resource Definitions).
:::

**Components installed:**

- **cert-manager** - Automatic TLS certificate management for services
- **external-secrets** - Synchronizes secrets from external stores (OCI Vault, AWS Secrets Manager, etc.)
- **metrics-server** - Provides container resource metrics for autoscaling
- **kube-state-metrics** - Exposes Kubernetes object metrics for monitoring
- **strimzi-kafka-operator** - Manages Kafka clusters via custom resources
- **oraoperator** - Oracle Database Operator for Kubernetes

**Install prerequisites:**

```bash
cd obaas-prereqs

# Install with default
helm upgrade --install obaas-prereqs . -n obaas-system --create-namespace [--debug] [--values <path_to_custom_values>]
```

**Verify installation:**

```bash
# Check all prerequisites pods are running
kubectl get pods -n obaas-system
```

**Expected state**: All pods should reach `Running` status within 2-3 minutes.

:::tip Wait for Prerequisites
Wait until all prerequisite pods are running before proceeding to install OBaaS.
:::

#### Step 2: Install OBaaS (Multiple Times)

If you're installing OBaaS using an ADB-S and not using **workload identity**, you need to create the namespace for OBaas and the secret containing the API key. You also need to change `values.yaml` file. There is a helper script called `tools/oci_config` that generates the `kubectl` command needed to create the secret. The secret name will be `oci-config-file`.

```bash
python3 tools/oci-config.py --namespace [namespace] 
```

After prerequisites are installed, you can install the OBaaS chart multiple times in different namespaces for multi-tenancy:

```bash
cd obaas

# Install for tenant 1
helm upgrade --install obaas-tenant1 . -n tenant1 --create-namespace [--debug] --values examples/values-tenant1.yaml

# Install for tenant 2
helm upgrade --install obaas-tenant2 . -n tenant2 --create-namespace [--debug] --values examples/values-tenant2.yaml

# Install for tenant N...
helm upgrade --install obaas-tenantN . -n tenantN --create-namespace [--debug] --values examples/values-tenantN.yaml
```

:::tip Example Configurations
See `obaas/examples/` directory for complete example values files for different scenarios.
:::

```bash
# Monitor the installation
kubectl get pods -n obaas-tenant1 -w
```

:::tip First Deployment
It may take 5-10 additional minutes for all pods to reach Running state.
:::

#### Step 3: Verify OBaaS Installation

After installation completes, verify all components are running:

```bash
# Check all pods are running
kubectl get pods -A
```

**Expected results:**

- All pods in `Running` state
- Services with ClusterIP or LoadBalancer IPs assigned
- Ingress configured with your hostname

### Architecture

**Why separate charts?**

The two-chart architecture provides flexibility and prevents conflicts:

- **obaas-prereqs**: Contains cluster-scoped operators and infrastructure that install CRDs (Custom Resource Definitions). These are cluster-wide resources that should only exist once. Installing multiple times would cause:
  - CRD version conflicts
  - Duplicate operator controllers
  - Resource contention

- **obaas**: Contains namespace-scoped resources that can be safely installed multiple times. Each instance:
  - Operates independently in its own namespace
  - Can create Kafka clusters via custom resources (managed by the shared Strimzi operator)
  - Has its own ingress controller and observability stack
  - Doesn't interfere with other OBaaS instances

**Architecture diagram:**

```tree
Cluster
├── obaas-system namespace (prerequisites)
│   ├── cert-manager
│   ├── external-secrets
│   ├── metrics-server
│   ├── kube-state-metrics
│   └── strimzi-kafka-operator (manages Kafka CRs across all namespaces)
├── tenant1 namespace (OBaaS instance 1)
│   ├── ingress-nginx
│   ├── APISIX, Eureka, Coherence, etc.
│   ├── Kafka cluster (CR managed by Strimzi)
│   └── Signoz + ClickHouse
└── tenant2 namespace (OBaaS instance 2)
    ├── ingress-nginx
    ├── APISIX, Eureka, Coherence, etc.
    ├── Kafka cluster (CR managed by Strimzi)
    └── Signoz + ClickHouse
```

### Configuration Options

See individual chart directories for detailed configuration options:

- [obaas-prereqs/README.md](http://TBD)
- [obaas/examples/](http://TBD) - Example configurations

### Uninstallation

To remove OBaaS from your cluster:

:::warning Data Loss
Uninstalling will delete all resources. Ensure you have backups of any important data before proceeding.
:::

**Step 1: Uninstall OBaaS instances first:**

```bash
# Uninstall each OBaaS instance
helm uninstall obaas -n obaas-prod
helm uninstall obaas-tenant1 -n tenant1
helm uninstall obaas-tenant2 -n tenant2
```

**Step 2: Delete namespaces (optional):**

```bash
kubectl delete namespace obaas-prod tenant1 tenant2
```

**Step 3: Uninstall prerequisites (only if removing entirely):**

```bash
helm uninstall obaas-prereqs -n obaas-system
```

:::danger Warning
Uninstalling prerequisites will affect **all** OBaaS instances in the cluster. Only do this if you're removing OBaaS completely.
:::

### Additional Resources

- **Chart Documentation**: See `obaas-prereqs/README.md` and `obaas/README.md` for detailed chart documentation
- **Example Configurations**: Check `obaas/examples/` directory for various deployment scenarios
- **Helm Values Reference**: Review `obaas/values.yaml` for all available configuration options
