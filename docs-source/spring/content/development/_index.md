---
title: "Development"
description: "How to develop and deploy Spring Boot applications with the Oracle Backend for Microservices and AI"
keywords: "spring springboot microservices development oracle backend"
---

This section provides information about how to develop and deploy Spring Boot applications with the Oracle Backend for Microservices and AI.

Spring Boot applications can be developed with no special requirements and be deployed into Oracle Backend for Microservices and AI.  However, if you do opt-in to the platform services provided and the CLI, you can shorten your development time and avoid unnecessary work.

Oracle Backend for Microservices and AI provides the following services that applications can use:

* An Oracle Autonomous Database instance in which applications can manage relational, document, spatial, graph and other types of data, can use Transactional Event Queues for messaging and events using Java Message Service (JMS), Apache Kafka or Representational State Transfer (REST) interfaces, and even run machine learning (ML) models.
* A Kubernetes cluster in which applications can run with namespaces pre-configured with Kubernetes Secrets and ConfigMaps for access to the Oracle Autonomous Database instance associated with the backend.
* An Apache APISIX API Gateway that can be used to expose service endpoints outside the Kubernetes cluster, to the public internet. All standard Apache APISIX features like traffic management, monitoring, authentication, and so on, are available for use.
* Spring Boot Eureka Service Registry for service discovery.  The API Gateway and monitoring services are pre-configured to use this registry for service discovery.
* Spring Cloud Config Server to serve externalized configuration information to applications. This stores the configuration data in the Oracle Autonomous Database instance associated with the backend.
* Netflix Conductor OSS for running workflows to orchestrate your services.
* Spring Admin for monitoring your services.
* SigNoz o for collecting and visualizing metrics, logs and traces.

An integrated development environment is recommended for developing applications. Oracle recommends Visual Studio Code or IntelliJ.

Java, Maven or Gradle, a version control system (Oracle recommends git), and other tools may be required during development.
