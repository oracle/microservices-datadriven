---
title: Setup with Helm or Marketplace
sidebar_position: 0
---

## Oracle Backend for Microservices and AI (OBaaS) - Deployment Options

Choose your preferred deployment method for OBaaS based on your requirements and existing infrastructure.

### Deployment Methods

#### Helm Charts

**Best for**: Deploying to existing Kubernetes clusters

**What you get**:

- **Flexible deployment** to existing Kubernetes cluster
- **Multi-tenancy support** - deploy multiple OBaaS instances
- **Granular control** over individual components
- **Use existing infrastructure** (cluster, database, networking)

**Prerequisites**:

- Existing Kubernetes cluster (1.33+)
- Helm 3.8+ installed
- kubectl configured
- Access to Oracle Database (19c+)

**[Get started with Helm Charts →](./helm/install.md)**

#### OCI Marketplace

**Best for:** Complete infrastructure provisioning on Oracle Cloud Infrastructure

**What you get**:

- Automated OKE cluster creation and configuration
- Autonomous Database provisioning (or BYO database support)
- Network infrastructure (VCN, subnets, load balancers, security lists)
- Complete OBaaS platform deployed and configured

**Prerequisites:**

- OCI tenancy with appropriate quotas and permissions

**[Get started with OCI Marketplace →](./oci_mp.md)**
