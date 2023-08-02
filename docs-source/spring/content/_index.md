---
title: "Oracle Backend for Spring Boot - Developer Preview"
---

# Oracle Backend for Spring Boot - Developer Preview

Oracle Backend for Spring Boot allows developers to build Microservices in Spring Boot and provisions a backend as a service with
Oracle Database and other infrastructure components that operate on multiple clouds. This service vastly simplifies the task of
building, testing, and operating Microservices platforms for reliable, secure, and scalable enterprise applications.

To learn more, watch this short introductory video:

{{< youtube 3MQy89oo894 >}}

In addition to an Oracle Autonomous Database Serverless instance, the following software components are deployed in an Oracle Cloud
Infrastructure (OCI) Container Engine for Kubernetes cluster (OKE cluster):

- Apache APISIX API Gateway and Dashboard
- Spring Boot Eureka service registry
- Spring Cloud Admin dashboard
- Spring Cloud Config server
- Netflix Conductor
- Prometheus
- Grafana
- OpenTelemetry Collector
- Jaeger
- HashiCorp Vault
- Apache Kafka
- Coherence

Developers also have access to development or build time services and libraries including:

- A command-line interface (CLI) to manage service deployment and configuration, including database schema management.
- Spring Data (Java Persistence API (JPA) and Oracle JDBC) to access Oracle Database.
- Oracle Java Database Connectivity (Oracle JDBC) drivers.
- Spring Cloud Config client.
- Spring Boot Eureka service discovery client.
- Spring Cloud OpenFeign.
- OpenTelemetry Collector (including automatic instrumentation).

&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Interested in Mobile or web apps too?" >}}
Check out [Oracle Backend for Parse Platform](https://oracle.github.io/microservices-datadriven/mbaas/)!
{{< /hint >}}
&nbsp;

## Developer Preview

This release is a *Developer Preview*. This means that not all functionality is complete. In this release, most of the planned services
and components are provided. However, additional configuration options and components may be provided in a future release. We are releasing
this as a *Developer Preview* to allow interested developers to try it and provide feedback.

