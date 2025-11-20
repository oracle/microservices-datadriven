---
title: Release Notes - 2.0.0-M5
sidebar_position: 1
description: Comprehensive release notes for Oracle Backend for Microservices and AI (OBaaS) version 2.0.0, including container images, platform components, and deployment information.
keywords: [OBaaS, Oracle Backend, microservices, AI, release notes, container images, Kubernetes, deployment, version 2.0.0]
---
## Overview

This document provides comprehensive information about the container images used in OBaaS (Oracle Backend as a Service) version 2.0.0-M5. It includes two primary image lists and a comparison to help you understand the differences between them.

### What's Included

- **Installed Images**: Images that are automatically deployed when using the production Helm installation
- **Required Images**: Complete list of images needed for OBaaS, useful when mirroring to private registries
- **Differences**: A comparison highlighting what's unique to each list

---

## Table of Contents

- [Overview](#overview)
- [Image Inventories](#image-inventories)
  - [Installed Images (Production Helm Deployment)](#installed-images-production-helm-deployment)
  - [Required Images (Complete Set)](#required-images-complete-set)
- [Image Differences Analysis](#image-differences-analysis)
  - [Summary](#summary)
  - [Detailed Comparison](#detailed-comparison)
    - [Additional Images in Required Set](#additional-images-in-required-set)
    - [Registry Path Differences](#registry-path-differences)

---

## Image Inventories

### Installed Images (Production Helm Deployment)

The following **29 images** are installed in the Kubernetes cluster when using the production installation via Helm charts. These represent the core components that are automatically deployed.

| Description | Image Name | Version |
|-------------|------------|---------|
| Observability Exporter | container-registry.oracle.com/database/observability-exporter | 2.2.0 |
| Operator | container-registry.oracle.com/database/operator | 1.2.0 |
| Otmm | container-registry.oracle.com/database/otmm | 24.4.1 |
| Coherence Operator | container-registry.oracle.com/middleware/coherence-operator | 3.5.6 |
| Clickhouse Operator | docker.io/altinity/clickhouse-operator | 0.21.2 |
| Metrics Exporter | docker.io/altinity/metrics-exporter | 0.21.2 |
| Apisix | docker.io/apache/apisix | 3.14.1-debian |
| Etcd | docker.io/bitnamilegacy/etcd | 3.5.10-debian-11-r2 |
| Zookeeper | docker.io/bitnamilegacy/zookeeper | 3.7.1 |
| Busybox | docker.io/busybox | 1.36 |
| Clickhouse Server | docker.io/clickhouse/clickhouse-server | 25.5.6 |
| Opentelemetry Collector Contrib | docker.io/otel/opentelemetry-collector-contrib | 0.109.0 |
| Signoz Otel Collector | docker.io/signoz/signoz-otel-collector | v0.129.4 |
| Signoz Schema Migrator | docker.io/signoz/signoz-schema-migrator | v0.129.4 |
| Signoz | docker.io/signoz/signoz | v0.94.1 |
| External Secrets | oci.external-secrets.io/external-secrets/external-secrets | v1.0.0 |
| Cert Manager Cainjector | quay.io/jetstack/cert-manager-cainjector | v1.16.2 |
| Cert Manager Controller | quay.io/jetstack/cert-manager-controller | v1.16.2 |
| Cert Manager Webhook | quay.io/jetstack/cert-manager-webhook | v1.16.2 |
| Kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.8.0 |
| Kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.9.1 |
| Operator | quay.io/strimzi/operator | 0.45.1 |
| Controller | registry.k8s.io/ingress-nginx/controller | v1.11.5 |
| Kube State Metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics | v2.17.0 |
| Metrics Server | registry.k8s.io/metrics-server/metrics-server | v0.7.2 |
| Admin Server | us-phoenix-1.ocir.io/maacloud/mark-artifactory/admin-server | 2.0.0-M5 |
| Conductor Server | us-phoenix-1.ocir.io/maacloud/mark-artifactory/conductor-server | 2.0.0-M5 |
| Eureka | us-phoenix-1.ocir.io/maacloud/mark-artifactory/eureka | 2.0.0-M5 |

---

**Generated on:** Wed Nov 19 20:12:29 CST 2025

---

### Required Images (Complete Set)

The following **42 images** represent the complete set of container images required for OBaaS installation. This list is particularly useful when:

- Setting up OBaaS in air-gapped or restricted environments
- Mirroring images to a private container registry
- Using the `private_repo_helper.sh` script to copy images to your own repository

**Note:** This list includes all installed images plus additional images needed for build processes, initialization tasks, and optional features.

| Description | Name | Version |
|-------------|------|---------|
| observability-exporter | container-registry.oracle.com/database/observability-exporter | 2.2.0 |
| operator | container-registry.oracle.com/database/operator | 1.2.0 |
| otmm | container-registry.oracle.com/database/otmm | 24.4.1 |
| coherence-ce | container-registry.oracle.com/middleware/coherence-ce | 25.03.2 |
| coherence-operator | container-registry.oracle.com/middleware/coherence-operator | 3.5.6 |
| adb-free | container-registry.oracle.com/database/adb-free | 25.10.2.1 |
| signoz-histograms | obaas-docker-release.dockerhub-iad.oci.oraclecorp.com/signoz-histograms | v0.0.1 |
| clickhouse-operator | docker.io/altinity/clickhouse-operator | 0.21.2 |
| metrics-exporter | docker.io/altinity/metrics-exporter | 0.21.2 |
| apisix | docker.io/apache/apisix | 3.14.1-debian |
| etcd | docker.io/bitnamilegacy/etcd | 3.5.10-debian-11-r2 |
| zookeeper | docker.io/bitnamilegacy/zookeeper | 3.7.1 |
| busybox | docker.io/busybox | 1.36 |
| clickhouse-server | docker.io/clickhouse/clickhouse-server | 25.5.6 |
| k8s-wait-for | docker.io/groundnuty/k8s-wait-for | v2.0 |
| yq | docker.io/linuxserver/yq | 3.4.3 |
| opentelemetry-collector-contrib | docker.io/otel/opentelemetry-collector-contrib | 0.109.0 |
| signoz | docker.io/signoz/signoz | v0.94.1 |
| signoz-otel-collector | docker.io/signoz/signoz-otel-collector | v0.129.4 |
| signoz-schema-migrator | docker.io/signoz/signoz-schema-migrator | v0.129.4 |
| external-secrets | oci.external-secrets.io/external-secrets/external-secrets | v1.0.0 |
| admin-server | phx.ocir.io/maacloud/mark-artifactory/admin-server | 2.0.0-M5 |
| conductor-server | phx.ocir.io/maacloud/mark-artifactory/conductor-server | 2.0.0-M5 |
| eureka | phx.ocir.io/maacloud/mark-artifactory/eureka | 2.0.0-M5 |
| cert-manager-cainjector | quay.io/jetstack/cert-manager-cainjector | v1.16.2 |
| cert-manager-controller | quay.io/jetstack/cert-manager-controller | v1.16.2 |
| cert-manager-startupapicheck | quay.io/jetstack/cert-manager-startupapicheck | v1.16.2 |
| cert-manager-webhook | quay.io/jetstack/cert-manager-webhook | v1.16.2 |
| kafka-bridge | quay.io/strimzi/kafka-bridge | 0.31.2 |
| kaniko-executor | quay.io/strimzi/kaniko-executor | 0.45.1 |
| maven-builder | quay.io/strimzi/maven-builder | 0.45.1 |
| operator | quay.io/strimzi/operator | 0.45.1 |
| kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.8.0 |
| kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.8.1 |
| kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.9.0 |
| kafka | quay.io/strimzi/kafka | 0.45.1-kafka-3.9.1 |
| curl-jq | registry.gitlab.com/gitlab-ci-utils/curl-jq | 3.2.0 |
| controller | registry.k8s.io/ingress-nginx/controller | v1.11.5 |
| kube-webhook-certgen | registry.k8s.io/ingress-nginx/kube-webhook-certgen | v1.5.2 |
| kube-state-metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics | v2.17.0 |
| metrics-server | registry.k8s.io/metrics-server/metrics-server | v0.7.2 |

---

## Image Differences Analysis

### Summary

The Required Images list contains **13 additional images** not present in the Installed Images list, plus **3 images with different registry paths**. These differences reflect the additional tooling and optional components needed for certain deployment scenarios.

### Detailed Comparison

#### Additional Images in Required Set

The following images are required for setup, builds, and optional features but are not part of the standard production deployment:

| Category | Description | Image Name | Version | Purpose |
|----------|-------------|------------|---------|---------|
| **Database** | Coherence CE | container-registry.oracle.com/middleware/coherence-ce | 25.03.2 | In-memory data grid runtime |
| **Database** | ADB Free | container-registry.oracle.com/database/adb-free | 25.10.2.1 | Autonomous Database Free tier |
| **Observability** | Signoz Histograms | obaas-docker-release.dockerhub-iad.oci.oraclecorp.com/signoz-histograms | v0.0.1 | Custom histogram processing |
| **Utilities** | K8s Wait For | docker.io/groundnuty/k8s-wait-for | v2.0 | Init container for waiting on resources |
| **Utilities** | YQ | docker.io/linuxserver/yq | 3.4.3 | YAML processing tool |
| **Utilities** | Curl-JQ | registry.gitlab.com/gitlab-ci-utils/curl-jq | 3.2.0 | HTTP client with JSON processing |
| **Certificate Management** | Cert Manager Startup API Check | quay.io/jetstack/cert-manager-startupapicheck | v1.16.2 | Cert-manager initialization validation |
| **Kafka/Streaming** | Kafka Bridge | quay.io/strimzi/kafka-bridge | 0.31.2 | HTTP bridge for Kafka |
| **Kafka/Streaming** | Kafka (3.8.1) | quay.io/strimzi/kafka | 0.45.1-kafka-3.8.1 | Additional Kafka version |
| **Kafka/Streaming** | Kafka (3.9.0) | quay.io/strimzi/kafka | 0.45.1-kafka-3.9.0 | Additional Kafka version |
| **Build Tools** | Kaniko Executor | quay.io/strimzi/kaniko-executor | 0.45.1 | Container image builder |
| **Build Tools** | Maven Builder | quay.io/strimzi/maven-builder | 0.45.1 | Java build tool |
| **Ingress** | Kube Webhook Certgen | registry.k8s.io/ingress-nginx/kube-webhook-certgen | v1.5.2 | Certificate generation for webhooks |

#### Registry Path Differences

The following images use different registry paths between the two lists:

| Image | Installed Images Registry | Required Images Registry | Version |
|-------|---------------------------|-------------------------|---------|
| admin-server | us-phoenix-1.ocir.io/maacloud/mark-artifactory | phx.ocir.io/maacloud/mark-artifactory | 2.0.0-M5 |
| conductor-server | us-phoenix-1.ocir.io/maacloud/mark-artifactory | phx.ocir.io/maacloud/mark-artifactory | 2.0.0-M5 |
| eureka | us-phoenix-1.ocir.io/maacloud/mark-artifactory | phx.ocir.io/maacloud/mark-artifactory | 2.0.0-M5 |

**Note:** Both registry paths point to the same Phoenix region but use different URL formats. The `phx.ocir.io` format is the shortened alias for `us-phoenix-1.ocir.io`.

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
