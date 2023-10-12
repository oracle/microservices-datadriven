---
title: "Release Notes"
---

## Version 1.0.0, October 15, 2023

This is the first production release.

Notes:

* All Spring platform components upgraded to Spring Boot 3.x, Spring 6.x and Spring Cloud 2022.0.4 versions.
* Spring Native (with GraalVM native image ahead of time compilation) is the default/recommended
  deployment option for microservices. JVM continues to be available as an option.
* Loki and Promtail added for logging, Spring Boot dashboard updated to show metrics and logs on the same dashboard.
* Spring Authorization Server added, and preconfigured with default users (you supply passwords during installation,
  or they are generated).  
* Various platform services and the CLI updated for authentication and authorization
  using Spring Authorization Server.
* Various platform services reconfigured for increased availability.
* Various components updated.

The following components were added:

| Component                    | Version   | Description                          |
|------------------------------|-----------|--------------------------------------|
| Loki                         | 2.6.1     | Provides log aggregation and search. |
| Promtail                     | 2.8.2     | Collects logs.                       |
| Spring Authorization Server  | 2022.0.4  | Provides authentication and authorization for applications. |

The following components were updated:

| Component                                                   | New Version   | Replaced Version    |
|-------------------------------------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot and Microservices Visual Studio Code extension | 1.0.0         | 0.3.9               |
| Oracle Backend for Spring Boot and Microservices CLI                          | 1.0.0         | 0.3.1               |
| Grafana                                                     | 9.5.2         | 9.2.5               |
| Spring Eureka Service Registry                              | 2022.0.4      | 2021.0.3            |
| Spring Config Server                                        | 2022.0.4      | 2021.0.3            |
| Spring Boot Admin                                           | 3.1.3         | 2.7.5               |
| cert-manager                                                | 1.12.3        | 1.11.0              |
| NGINX Ingress Controller                                    | 1.8.1         | 1.6.4               |
| Prometheus                                                  | 2.40.2        | 2.34.0              |
| Open Telemetry Collector                                    | 0.86.0        | 0.66.0              |
| Jaeger Tracing                                              | 1.45.0        | 1.39.0              |
| APISIX API Gateway                                          | 3.4.0         | 3.2.0               |
| Strimzi-Apache Kafka operator                               | 0.36.1        | 0.33.1              |
| Apache Kafka                                                | 3.4.0 - 3.5.1 | 3.2.0 - 3.3.2       |
| Oracle Database storage adapter for Parse (optional)        | 1.0.0         | 0.2.0               |

There were no component deprecations or removals.

## Developer Preview 0.7.0, July 24, 2023

Notes:

* Continued incremental improvements to Oracle Database Adapter for Parse Server.

The following components were added:

| Component                    | Version   | Description         |
|------------------------------|---------------|---------------------|
| Coherence | 3.2.11 | Provides in-memory data grid. |

The following components were updated:

| Component                    | New Version   | Replaced Version    |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot and Microservices Visual Studio Code extension | 0.3.9 | 0.3.8 |
| HashiCorp Vault              |  1.14.0 | v1.11.3 |
| Oracle Database Operator for Kubernetes | 1.0 | 0.6.1 |
| Parse Server                 | 6.2.0  | 5.2.7 |
| Parse Dashboard              | 5.1.0 | 5.0.0 |
| Oracle Transaction Manager for Microservices | 22.3.2 | 22.3.1 |

There were no component deprecations or removals.

## Developer Preview 0.3.1, June 14, 2023

Notes:

* Improvements to Oracle Cloud Infrastructure (OCI) installation process.
* Continued incremental improvements to Oracle Database Adapter for Parse Server.

No components were added.

The following components were updated:

| Component                    | New Version   | Replaced Version    |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot and Microservices CLI | 0.3.1   | 0.3.0               |
| Oracle Backend for Spring Boot and Microservices Visual Studio Code extension | 0.3.8 | 0.3.7 |

There were no component deprecations or removals.

## Developer Preview 0.3.0, April 17, 2023

Notes:

* Oracle Backend for Spring Boot and Microservices now includes the option to install in a Multicloud (OCI/Azure) environment.
* The Oracle Database Operator for Kubernetes is bound to the existing Oracle Autonomous Database (ADB) created by infrastructure as code (IaC) in an all-OCI installation and provisions the ADB in the Multicloud installation.
* Improvements to On-Premises and desktop installation processes.

The following components were added:

| Component                    | New Version   | Description         |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot and Microservices Visual Studio Code extension | 0.3.7   |  Allows Visual Studio Code users to manage the platform, deployments and configuration.  |

The following components were updated:

| Component                    | New Version   | Replaced Version    |
|------------------------------|---------------|---------------------|
| Oracle Backend for Spring Boot and Microservices CLI | 0.3.0   | 0.1.0               |

There were no component deprecations or removals.

## Developer Preview 0.2.3, March 8, 2023

Notes:

* Oracle Backend for Spring Boot and Microservices now includes the option to also install Parse Platform in the same deployment.
* Oracle Backend for Spring Boot and Microservices CLI 0.2.3 includes a number of bug fixes and adds support for custom listening ports for services.
* Apache APISIX is now pre-configured for both Eureka and Kubernetes service discovery.

The following components were added:

| Component                    | Version       | Description                                                                             |
|------------------------------|---------------|-----------------------------------------------------------------------------------------|
| Oracle Database Operator for Kubernetes | 0.6.1 | Helps reduce the time and complexity of deploying and managing Oracle databases.     |  
| Parse Server                 | 5.2.7        | Provides backend services for mobile and web applications.                               |
| Parse Dashboard              | 5.0.0        | Uses a web user interface for managing Parse Server.                                            |
| Oracle Database Adapter for Parse Server | 0.2.0    | Enables the Parse Server to store data in an Oracle database.                           |

The following components were updated:

| Component                                            | New Version | Replaced Version |
|------------------------------------------------------|-------------|------------------|
| Oracle Backend for Spring Boot and Microservices CLI | 0.2.3       | 0.1.0            |
| cert-manager                                         | 1.11.0      | 1.10.1           |
| NGINX Ingress Controller                             | 1.6.4       | 1.5.1            |
| Jaeger Tracing                                       | 1.39.0      | 1.37.0           |
| Apache APISIX                                        | 3.1.1       | 2.15.1           |
| Spring Boot Eureka service registry                  | 2.0.1       | 2021.0.3         |
| Oracle Transaction Manager for Microservices         | 22.3.2      | 22.3.1           |
| Parse Server (optional)                              | 6.3.0       | 6.2.0            |
| Parse Dashboard (optional)                           | 5.2.0       | 5.1.0            |


There were no deprecations or removals.

## Developer Preview 0.2.0, February 27, 2023

The following components were added:

| Component                    | Version       | Description                                                                             |
|------------------------------|---------------|-----------------------------------------------------------------------------------------|
| Oracle Transaction Manager for Microservices | 22.3.1 | Manages distributed transactions to ensure consistency across Microservices.   |
| Strimzi-Apache Kafka Operator       | 0.33.1        | Manages Apache Kafka clusters.                                                        |
| Apacha Kafka                 | 3.2.0 - 3.3.2 | Allows distributed event streaming.                                                            |

There were no deprecations or removals.

## Developer Preview 0.1.0, January 30, 2023

The following components were added:

| Component                    | Version      | Description                                                                              |
|------------------------------|--------------|------------------------------------------------------------------------------------------|
| HashiCorp Vault              | v1.11.3      | Provides a way to store and tightly control access to sensitive data.                    |
| Oracle Backend for Spring Boot and Microservices CLI | 0.1.0  | Provides a command-line interface to manage application deployment and configuration.               |
| Netflix Conductor OSS        | 3.13.2       | Provides workflow orchestration for Microservices.                                       |
| On-premises installer        | 0.1.0        | Allows installation of a self-hosted stack.                                              |

There were no deprecations or removals.

## Developer Preview 0.0.1, December 20, 2022

This release includes the following components:

| Component                    | Version      | Description                                                                              |
|------------------------------|--------------|------------------------------------------------------------------------------------------|
| cert-manager                 | 1.10.1       | Automates the management of certificates.                                                |
| NGINX Ingress Controller     | 1.5.1        | Provides a traffic management solution for cloud native applications in Kubernetes.        |
| Prometheus                   | 2.40.2       | Provides event monitoring and alerting.                                                  |
| Prometheus operator          | 0.60.1       | Provides management for Prometheus monitoring tools.                                     |
| OpenTelemetry Collector      | 0.66.0       | Collects process and export telemetry data.                                              |
| Grafana                      | 9.2.5        | Examines, analyzes, and monitors metrics.                                                |
| Jaeger Tracing               | 1.37.0       | Provides a distributed tracing system for monitoring and troubleshooting distributed systems.       |
| Apache APISIX                | 2.15.1       | Provides full lifecycle API management.                                                  |
| Spring Cloud Admin server     | 2.7.5        | Manages and monitors Spring Boot applications.                                           |
| Spring Cloud Config server   | 2.7.5        | Provides server-side support for externalized configuration.                             |
| Spring Boot Eureka service registry      | 2021.0.3     | Provides service discovery capabilities.                                                 |
