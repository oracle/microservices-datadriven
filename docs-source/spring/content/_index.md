---
title: "Oracle Backend for Spring Boot and Microservices"
description: "Spring and Spring Boot"
keywords: "spring springboot microservices development oracle backend"
---

Oracle Backend for Spring Boot and Microservices allows developers to build microservices in Spring Boot and provisions a "backend as a service" with Oracle Database and other infrastructure components that operate on multiple clouds. Oracle Backend for Spring Boot and Microservices vastly simplifies the task of building, testing, and operating microservices platforms for reliable, secure, and scalable enterprise applications.

&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Version 1.3.0 (production) released September, 2024" >}}
 Oracle Backend for Spring Boot and Microservices Version 1.3.0 is now generally available and suitable for production use. This version supports and recommends Spring Boot 3.3.x, 3.2.x, Spring 6.1 and Spring Cloud 2023.0.x, with limited backwards compatibility for Spring Boot 2.7.x.  
{{< /hint >}}
&nbsp;

To learn more, watch this short introductory video:

{{< youtube 3MQy89oo894 >}}

In addition to an Oracle Autonomous Database Serverless instance, the following software components are deployed in an Oracle Cloud
Infrastructure (OCI) Container Engine for Kubernetes cluster (OKE cluster):

- [Apache APISIX API Gateway and Dashboard](platform/apigw/)
- [Apache Kafka](https://kafka.apache.org/)
- [Grafana](observability/metrics/)
- [HashiCorp Vault](platform/vault/)
- [Jaeger](observability/tracing/)
- [Apache Kafka](https://kafka.apache.org)
- Loki
- [Netflix Conductor](platform/conductor/)
- [OpenTelemetry Collector](observability/tracing/)
- [Oracle Autonomous Database Serverless](database/)
- [Oracle Backend for Spring Boot Command Line Interface (CLI)](development/cli/)
- [Oracle Backend for Spring Boot Visual Studio Code Plugin](platform/vscode-plugin/)
- [Oracle Coherence](https://docs.oracle.com/en/middleware/standalone/coherence/)
- [Oracle Database Operator for Kubernetes (OraOperator or the operator)](https://github.com/oracle/oracle-database-operator)
- Oracle Database Observability Exporter
- [Oracle Transaction Manager for Microservices (MicroTx)](platform/microtx/)
- [Prometheus](observability/metrics/)
- Promtail
- [Spring Boot Admin dashboard](platform/spring-admin/)
- [Spring Cloud Config server](platform/config/)
- [Spring Cloud Eureka service registry](platform/eureka/)
- [Spring Operations Center](platform/soc/)
- Strimzi Kafka Operator

Developers also have access to development or build time services and libraries including:

- A command-line interface [(CLI)](development/cli/) to manage service deployment and configuration, including database schema management.
- [Visual Studio Code (VS Code) plugin](platform/vscode-plugin/) to manage service deployment and configuration.
- [Spring CLI](https://spring.io/projects/spring-cli) support for project creation.
- Spring Data (Java Persistence API (JPA) and Oracle JDBC) to access Oracle Database.
- Oracle Java Database Connectivity (Oracle JDBC) drivers.
- [Spring Cloud Config client](platform/config/).
- [Spring Eureka service discovery client](platform/eureka/).
- [Spring Cloud OpenFeign](https://spring.io/projects/spring-cloud-openfeign).
- [OpenTelemetry Collector (including automatic instrumentation)](observability/tracing/).
- [Spring Starters for Oracle Universal Connection Pool (UCP), Oracle Wallet, Oracle Advanced Queuing (AQ), and Transactional Event Queues (TxEventQ)](starters/).

## Learn more, try it out with CloudBank!

To learn more about deploying and using Oracle Backend for Spring Boot and Microservices, we recommend our
[CloudBank](https://bit.ly/CloudBankOnOBaaS) self-paced, on-demand hands-on lab.

![CloudBank LiveLab](./cloudbank-hol.png)

In the [CloudBank](https://bit.ly/CloudBankOnOBaaS) hands-on lab, you can learn how to:

- Install Oracle Backend for Spring Boot and Microservices.
- Set up a development environment for Spring Boot.
- Build Spring Boot microservices from scratch using Spring Web to create
  Representational State Transfer (REST) services.
- Use service discovery and client-side load balancing.
- Use Spring Actuator to allow monitoring of services.
- Create services that use asynchronous messaging with Java Message Service (JMS) instead of REST.
- Implement the Saga pattern to manage data consistency across microservices.
- Use the APISIX API Gateway to expose services to clients.
- Extend a provided Flutter client to add a new "cloud cash" feature that uses the services you have built.

## Need help?

We'd love to hear from you!  You can contact us in the
[#oracle-db-microservices](https://oracledevs.slack.com/archives/C06L9CDGR6Z) channel in the
Oracle Developers slack workspace, or [open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
