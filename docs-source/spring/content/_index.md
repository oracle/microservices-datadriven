---
title: "Oracle Backend for Spring Boot and Microservices"
---

Oracle Backend for Spring Boot and Microservices allows developers to build microservices in Spring Boot and provisions a "backend as a service" with
Oracle Database and other infrastructure components that operate on multiple clouds. Oracle Backend for Spring Boot and Microservices vastly simplifies the task of
building, testing, and operating microservices platforms for reliable, secure, and scalable enterprise applications.

To learn more, watch this short introductory video:

{{< youtube 3MQy89oo894 >}}

In addition to an Oracle Autonomous Database Serverless instance, the following software components are deployed in an Oracle Cloud
Infrastructure (OCI) Container Engine for Kubernetes cluster (OKE cluster):

- Apache APISIX API Gateway and Dashboard
- Apache Kafka
- Coherence
- Grafana
- HashiCorp Vault
- Jaeger
- Loki
- Netflix Conductor
- OpenTelemetry Collector
- Oracle Autonomous Database Serverless
- Oracle Database Operator for Kubernetes (OraOperator or the operator)
- Oracle Transaction Manager for Microservices (MicroTx)
- Prometheus
- Promtail
- Spring Eureka service registry
- Spring Boot Admin dashboard
- Spring Cloud Config server

Developers also have access to development or build time services and libraries including:

- A command-line interface (CLI) to manage service deployment and configuration, including database schema management.
- Visual Studio Code (VS Code) plugin to manage service deployment and configuration.
- Spring Data (Java Persistence API (JPA) and Oracle JDBC) to access Oracle Database.
- Oracle Java Database Connectivity (Oracle JDBC) drivers.
- Spring Cloud Config client.
- Spring Eureka service discovery client.
- Spring Cloud OpenFeign.
- OpenTelemetry Collector (including automatic instrumentation).

## Learn more, try it out with CloudBank!

To learn more about deploying and using Oracle Backend for Spring Boot and Microservices, we recommend our
[CloudBank](https://bit.ly/CloudBankOnOBaaS) self-paced, on-demand hands-on lab.

![](./cloudbank-hol.png)

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

&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Interested in Mobile or web apps too?" >}}
Check out [Oracle Backend for Parse Platform](https://oracle.github.io/microservices-datadriven/mbaas/)!
{{< /hint >}}
&nbsp;



