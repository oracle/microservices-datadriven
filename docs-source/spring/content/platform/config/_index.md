---
title: Configuration
---

Oracle Backend as a Service for Spring Cloud includes the Spring Config which provides server and client-side support for externalized
configuration in a distributed system. The Spring Config Server provides a central place to manage external properties for applications
across all environments.

The Spring Config Server is pre-configured to work with the Spring Eureka Service Registry, and it is configured to store the configuration
in the Oracle Autonomous Database, so it easily supports labelled versions of configuration
environments, as well as being accessible to a wide range of tooling for managing the content.
Configuration is stored in the `CONFIGSERVER` schema in the `PROPERTIES` table.

An example of a Config Server client's Spring `application.yaml` configuration file could include:

```
spring:
  config:
    import: optional?configserver:http://config-server.config-server.svc.cluster.local:8080
  application:
    name: atael
  cloud:
    config:
      label: latest
      profile: dev
```

This will fetch data in the value where the application is `atael`, profile is `dev` and the lable is `latest`.

Managing the data for the Config Server should be done using the CLI.  If you prefer, you can also work directly with the `CONFIGSERVER.PROPERTIES` table in the database.