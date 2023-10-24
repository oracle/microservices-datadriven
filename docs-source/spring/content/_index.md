---
title: "Oracle Backend for Spring Boot and Microservices"
---

Oracle Backend for Spring Boot and Microservices allows developers to build microservices in Spring Boot and provisions a "backend as a service" with
Oracle Database and other infrastructure components that operate on multiple clouds. Oracle Backend for Spring Boot and Microservices vastly simplifies the task of
building, testing, and operating microservices platforms for reliable, secure, and scalable enterprise applications.

&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Version 1.0 (production) released October, 2023" >}}
 Oracle Backend for Spring Boot and Microservices Version 1.0 is now generally available and suitable
 for production use.  This version supports and recommends Spring Boot 3.1.x, Spring 6.0 and Spring Cloud 2022.0.4,
 with limited backwards compatibility for Spring Boot 2.7.x.  
{{< /hint >}}
&nbsp;

To learn more, watch this short introductory video:

{{< youtube 3MQy89oo894 >}}

In addition to an Oracle Autonomous Database Serverless instance, the following software components are deployed in an Oracle Cloud
Infrastructure (OCI) Container Engine for Kubernetes cluster (OKE cluster):

- Apache APISIX API Gateway and Dashboard
- Apache Kafka
- Coherence
- Conductor Server
- Grafana
- HashiCorp Vault
- Jaeger
- Apache Kafka
- Loki
- Netflix Conductor
- OpenTelemetry Collector
- Oracle Autonomous Database Serverless
- Oracle Backend for Spring Boot Command Line Interface (CLI)
- Oracle Backend for Spring Boot Visual Studio Code Plugin
- Oracle Database Operator for Kubernetes (OraOperator or the operator)
- Oracle Transaction Manager for Microservices (MicroTx)
- Parse and Parse Dashboard (Optional)
- Prometheus
- Promtail
- Spring Boot Admin dashboard
- Spring Cloud Config server
- Spring Cloud Eureka service registry
- Strimzi Kafka Operator

Developers also have access to development or build time services and libraries including:

- A command-line interface (CLI) to manage service deployment and configuration, including database schema management.
- Visual Studio Code (VS Code) plugin to manage service deployment and configuration.
- Spring Data (Java Persistence API (JPA) and Oracle JDBC) to access Oracle Database.
- Oracle Java Database Connectivity (Oracle JDBC) drivers.
- Spring Cloud Config client.
- Spring Eureka service discovery client.
- Spring Cloud OpenFeign.
- OpenTelemetry Collector (including automatic instrumentation).
- Spring Starters for Oracle Universal Connection Pool (UCP), Oracle Wallet, Oracle Advanced Queuing (AQ), and Transactional Event Queues (TxEventQ).

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

# Need help?

We'd love to hear from you!  You can contact us in the
[#oracle-db-microservices](https://oracledevs.slack.com/archives/C03ALDSV272) channel in the
Oracle Developers slack workspace, or [open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).


&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Interested in Mobile or web apps too?" >}}
Check out [Oracle Backend for Parse Platform](https://oracle.github.io/microservices-datadriven/mbaas/) - our "MERN"
stack for Oracle Database!  Available as an optional component in Oracle Backend for Spring Boot and Microservices.
{{< /hint >}}
&nbsp;
