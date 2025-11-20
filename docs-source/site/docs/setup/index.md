---
title: Setup Overview
sidebar_position: 0
description: Complete setup and installation guide for Oracle Backend for Microservices and AI (OBaaS). Compare production vs development environments, understand installation requirements, and choose the right deployment path for your needs.
keywords: [OBaaS, Oracle Backend, microservices, AI, setup, installation, production environment, development environment, Kubernetes, deployment, Helm, APISIX, Kafka, Coherence, Conductor, OTMM, observability]
---

# Overview

Welcome to the OBaaS setup guide. This section will help you install and configure Oracle Backend for Microservices and AI for your environment.

## Table of Contents

- [Choosing Your Installation Path](#choosing-your-installation-path)
  - [Production Environment](#production-environment)
  - [Development Environment](#development-environment)
- [Getting Help](#getting-help)

---

## Choosing Your Installation Path

OBaaS offers two installation paths tailored to different use cases:

### Production Environment

The Production installation uses Helm charts for deployment and assumes that your infrastructure is already in place, including network infrastructure, Kubernetes cluster, and Oracle Database. All prerequisites must be met before beginning the installation.

**Best for:**
- Production deployments requiring high availability and security
- Multi-tenant environments with resource isolation
- Enterprise deployments with external secrets management
- Comprehensive observability and monitoring requirements
- Teams requiring full platform capabilities

For complete prerequisite details, see the [Prerequisites Guide](./setup_prod/prereqs.md).

**What's included:**
- Complete platform component installation (APISIX, Kafka, Coherence, Conductor, etc.)
- Oracle Database with Transaction Manager for Microservices (OTMM)
- Full observability stack (metrics, logs, traces)
- External Secrets Operator for credential management
- Production-grade configuration and security settings

[**→ Go to Production Setup**](./setup_prod/setup.md)

---

### Development Environment -- TBD

The Development installation uses Terraform to deploy both infrastructure and OBaaS, designed specifically for development and testing environments. This approach offers lower customization compared to Production but provides a faster, automated setup. The Terraform scripts support deployment on Azure, OCI, and AWS cloud platforms. Oracle OCI users can also leverage Oracle Resource Manager (ORM) for infrastructure deployment.

**Best for:**
- Local development and testing
- Learning OBaaS features and capabilities
- Rapid prototyping and experimentation
- Resource-constrained environments
- Single-developer or small team environments

**What's included:**
- Complete platform component installation (APISIX, Kafka, Coherence, Conductor, etc.)
- Oracle Database with Transaction Manager for Microservices (OTMM)
- Full observability stack (metrics, logs, traces)
- External Secrets Operator for credential management
- Production-grade configuration and security settings

[**→ Go to Development Setup**](./setup_dev/setup.md)

---

## Getting Help

Each installation path includes:
- Detailed step-by-step instructions
- Example commands and configurations
- Verification steps and expected outputs
- Troubleshooting guidance
- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).

#oracle-db-microservices Slack channel in the Oracle Developers slack workspace.
Open an issue in GitHub.

Choose the path that matches your requirements and follow the guides in sequence.
