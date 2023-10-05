---
title: "Configuration"
---

Oracle Backend for Spring Boot and Microservices includes Spring Cloud Config which provides server- and client-side support for externalized
configurations in a distributed system. The Spring Cloud Config server provides a central place to manage external properties for applications
across all environments.

The Spring Cloud Config server is pre-configured to work with the Spring Boot Eureka service registry, and it is configured to store the
configuration in the Oracle Autonomous Database, so it easily supports labelled versions of configuration
environments, as well as being accessible to a wide range of tools for managing the content.
Configuration is stored in the `CONFIGSERVER` schema in the `PROPERTIES` table.

For example, the Spring Cloud Config client's Spring `application.yaml` configuration file could include:

```yaml
spring:
  config:
    import: optional:configserver:http://config-server.config-server.svc.cluster.local:8080
  application:
    name: atael
  cloud:
    config:
      label: latest
      profile: dev
```

This example fetches data where the application is `atael`, profile is `dev` and the label is `latest`.

Managing the data for the Spring Cloud Config server should be done using the CLI. If you prefer, you can also work directly
with the `CONFIGSERVER.PROPERTIES` table in the database.

