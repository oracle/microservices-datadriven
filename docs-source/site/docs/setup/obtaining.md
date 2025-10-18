---
title: Obtaining Installation Package
sidebar_position: 3
---
## Obtaining the Installation Package

## Overview

The OBaaS installation package contains all necessary Helm charts for deploying OBaaS components in your Kubernetes cluster.

## Package Location

The installation package is located in the [helm](http://tbd) directory with the following structure:

```text
.
├── private_repo_helper.sh
├── obaas
├── obaas-db
├── obaas-observability
└── obaas-prereqs
```

## Helm Charts

The installation package includes four Helm charts, each serving a specific purpose in the OBaaS deployment:

### OBaaS Prerequisites

**Directory:** `obaas-prereqs`

Contains cluster-level components shared by all OBaaS installations within a cluster.

**Key characteristics:**

- Installed at the cluster level
- Shared across all OBaaS instances in the cluster
- Can only be installed once per cluster

**Components include:**

- Cert Manager
- External Secrets Operator
- Ingress controllers
- Other foundational infrastructure

### OBaaS Database

**Directory:** `obaas-db`

Contains components that manage the OBaaS database layer.

**Key characteristics:**

- Manages database operations and connections
- Supports Oracle Autonomous Database integration
- Includes Oracle Database Operator

**Components include:**

- Oracle Database Operator
- Database connection management
- Schema and credential management

### OBaaS Observability

**Directory:** `obaas-observability`

Contains components for the optional observability stack.

**Key characteristics:**

- Optional installation
- Based on SigNoz
- Provides monitoring and metrics capabilities

**Components include:**

- Metrics collection
- Logging infrastructure
- Monitoring dashboards
- Alert management

### OBaaS Core

**Directory:** `obaas`

Contains the core OBaaS components and platform services.

**Key characteristics:**

- Main application components
- Platform services and runtime
- Service mesh and API gateway

**Components include:**

- Eureka (service discovery)
- Admin Server
- Configuration Server
- API Gateway (APISIX)
- Kafka messaging
- Coherence caching
- Application runtime components

## Installation Order

Install the Helm charts in the following sequence:

1. [OBaaS Prerequisites](./prereq-chart.md) (once per cluster)
2. [OBaaS Observability](./observability.md) (optional)
3. [OBaaS Database](./database.md)
4. [OBaaS Core](./obaas.md)

:::important
The prerequisites chart must be installed first and can only be installed once per cluster. All other charts depend on the components provided by the prerequisites.
:::

## Helper Scripts

### private_repo_helper.sh

The `private_repo_helper.sh` script assists with configuring private container registries.

**Usage:**

```bash
./private_repo_helper.sh
```

This script helps you:

- Configure image pull secrets
- Update chart values to point to private repositories
- Set up registry authentication
