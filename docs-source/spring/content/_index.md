---
title: "Oracle Backend for Spring Boot - Developer Preview"
---

Oracle Backend for Spring Boot allows developers to build microservices in Spring Boot and provision a backend as a service with the Oracle Database and other infrastructure components that operate on multiple clouds. This service vastly simplifies the task of building, testing, and operating microservices platforms for reliable, secure, and scalable enterprise applications.

Learn more in this short introduction video:

{{< youtube 3MQy89oo894 >}}

In addition to an Oracle Autonomous Database Shared instance, the following software components are deployed in an Oracle Cloud Infrastructure Container Engine for Kubernetes (OKE) cluster:

- APISIX API Gateway and Dashboard
- Spring Eureka Service Registry
- Spring Admin Dashboard
- Spring Config Server
- Netflix Conductor
- Prometheus
- Grafana
- Open Telemetry Collector
- Jaeger
- HashiCorp Vault

Developers also have access to development/build time services and libraries including:

- A CLI to manage service deployment and configuration, including database schema management
- Spring Data (JPA, JDBC) to access Oracle Database
- Oracle JDBC drivers
- Spring Config client
- Spring Eureka Service Discovery client
- OpenFeign
- Open Telemetry (including automatic instrumentation)

&nbsp;
{{< hint type=[warning] icon=gdoc_fire title="Interested in Mobile or web apps too?" >}}
Check out [Oracle Backend for Parse Platform](https://oracle.github.io/microservices-datadriven/mbaas/)!
{{< /hint >}}
&nbsp;

## Developer Preview

This release is a *Developer Preview*. This means that not all functionality is complete. In this release, most of the planned services and components are provided, however additional configuration options and components may be provided in a future release. We are releasing this as a developer preview to allow interested developers to try it and give feedback.
