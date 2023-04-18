## Developer Preview 0.3.0, April 17, 2023

Notes:
* Oracle Backend for Spring Boot now includes the option to install in a Multi-Cloud (OCI/Azure) Environment.
* The Oracle Database Operator for Kubernetes will be bound the existing ADB created by IaC in an all-OCI installation and will provision the ADB in the multi-cloud installation.
* Improvements to On-Premises and Desktop Installation process

The following components were added:

| Component                    | New Version   | Description         |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot Visual Studio Code Extension | 0.3.7   |  Allows Visual Studio Code users to manage the platform, deployments and configuration.  |

The following components were updated:

| Component                    | New Version   | Replaced Version    |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot CLI | 0.3.0   | 0.1.0               |

There were no component deprecations or removals.

## Developer Preview 0.2.3, March 8, 2023

Notes: 

* Oracle Backend for Spring Boot now includes the option to also install Parse Platform in the same deployment.
* Oracle Backend for Spring Boot CLI 0.2.3 includes a number of bug fixes, and adds support for custom listen ports for services.
* APISIX is now pre-configured for both Eureka and Kubernetes service discovery.

The following components were added:

| Component                    | Version       | Description                                                                             |
|------------------------------|---------------|-----------------------------------------------------------------------------------------|
| Oracle Database Operator for Kubernetes | 0.6.1 | Helps reduce the time and complexity of deploying and managing Oracle Databases      |  
| Parse Server                 | 5.2.7        | Provides backend services for mobile and web applications                                |
| Parse Dashboard              | 5.0.0        | Web user interface for managing Parse Server                                             |
| Oracle Storage Adapter for Parse | 0.2.0    | Enables Parse Server to store data in Oracle Database                                    |


The following components were updated:

| Component                    | New Version   | Replaced Version    |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot CLI | 0.2.3   | 0.1.0               |
| cert-manager                 | 1.11.0        | 1.10.1              |
| NGNIX Ingress Controller     | 1.6.4         | 1.5.1               |
| Jaeger Tracing               | 1.39.0        | 1.37.0              |
| APISIX                       | 3.1.1         | 2.15.1              |
| Eureka Service Registry      | 3.1.4         | 2021.0.3            |

There were no deprecations or removals.

## Developer Preview 0.2.0, February 27, 2023

The following components were added:

| Component                    | Version       | Description                                                                             |
|------------------------------|---------------|-----------------------------------------------------------------------------------------|
| Oracle Transaction Manager for Microservices | 22.3.1 | Manages distributed transactions to ensure consistency across microservices    |
| Strimzi Kafka Operator       | 0.33.1        | Manages Kafka clusters                                                                  |
| Apacha Kafka                 | 3.2.0 - 3.3.2 | Distributed event streaming                                                             |

There were no deprecations or removals.

## Developer Preview 0.1.0, January 30, 2023

The following components were added:

| Component                    | Version      | Description                                                                              |
|------------------------------|--------------|------------------------------------------------------------------------------------------|
| HashiCorp Vault              | v1.11.3      | Provides a way of store and tightly control access to sensitive data                     |
| Oracle Backend for Spring Boot CLI | 0.1.0  | Command line tool to manage application deployment and configuration                     |
| Netflix Conductor OSS        | 3.13.2       | Workflow orchestration for microservices                                                 |
| On-premises installer        | 0.1.0        | Allows you to install a self-hosted stack                                                |

There were no deprecations or removals.

## Developer Preview 0.0.1, December 20, 2022

This release includes the following components:

| Component                    | Version      | Description                                                                              |
|------------------------------|--------------|------------------------------------------------------------------------------------------|
| cert-manager                 | 1.10.1       | Automates the management of certificates.                                                |
| NGINX Ingress Controller     | 1.5.1        | Traffic management solution for cloud‑native applications in Kubernetes.                 |
| Prometheus                   | 2.40.2       | Provides event monitoring and alerting.                                                  |
| Prometheus Operator          | 0.60.1       | Provides management for Prometheus monitoring tools.                                     |
| OpenTelemetry Collector      | 0.66.0       | Collects process and export telemetry data.                                              |
| Grafana                      | 9.2.5        | Tool to help you examine, analyze, and monitor metrics.                                  |
| Jaeger Tracing               | 1.37.0       | Distributed tracing system for monitoring and troubleshooting distributed systems.       |
| APISIX                       | 2.15.1       | Provides full lifecycle API Management.                                                  |
| Spring Admin Server          | 2.7.5        | Managing and monitoring Spring Boot applications.                                        |
| Spring Cloud Config Server   | 2.7.5        | Provides server-side support for externalized configuration.                             |
| Eureka Service Registry      | 2021.0.3     | Provides Service Discovery capabilities                                                  |
