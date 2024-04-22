---
title: "Predefined Variables"
description: "Predefined environment variables in Oracle Backend for Spring Boot and Microservices"
keywords: "predefined variables spring springboot microservices development oracle backend"
---

When you deploy a Spring Boot application using the Oracle Backend for Spring Boot and Microservices CLI or Visual Code extension, a number of predefined environment variables will be injected into the pod definition. You may reference any of these variables in your application.

The predefined variables are as follows:

- `app.container.port`, for example `8080`.  
  This sets the listen port for the pod and service.  The Spring Boot application will listen on this port.  The default is `8080`.  This can be set using the `--port` parameter on the `deploy` command in the CLI.
- `spring.profiles.active`, for example `default`.  
  This sets the Spring profiles that will be active in the application.  The default value is `default`.  This can be changed set the `--service-profile` parameter on the `deploy` command in the CLI.
- `spring.config.label`, for example `0.0.1`.  
  This is a label that can be used with Spring Config to look up externalized configuration from Spring Config Server, along with the application name and the profile.
- `eureka.instance.preferIpAddress`, for example `true`.  
  This tells the Eureka discovery client to use the `preferIpAddress` setting.  This is required in Kubernetes so that service discover will work correctly.
- `eureka.instance.hostname`, for example `customer32.application`.  
  This sets the hostname that Eureka will use for this application.
- `MP_LRA_COORDINATOR_URL`, for example `http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator`.  
  This is the URL for the transaction manager which is required when using Eclipse Microprofile Long Running Actions in your application.
- `MP_LRA_PARTICIPANT_URL`, for example `http://customer32.application.svc.cluster.local:8080`.  
  This is the participant URL which is required when using Eclipse Microprofile Long Running Actions in your application.
- `eureka.client.register-with-eureka`, for example `true`.  
  This tells the Eureka discovery client to register with the Eureka server.
- `eureka.client.fetch-registry`, for example `true`.  
  This tells the Eureka discovery client to make a local copy of the registry by fetching it from the Eureka server.
- `eureka.client.service-url.defaultZone`, for example `http://eureka.eureka:8761/eureka`.  
  This is the default zone for the Eureka discovery client.
- `zipkin.base-url`, for example `http://jaegertracing-collector.observability.svc.cluster.local:9411/api/v2/spans`.  
  This is the URL of the Zipkin-compatible trace collector which can be used by your application to send trace data to the platform.
- `otel.exporter.otlp.endpoint`, for example `http://open-telemetry-opentelemetry-collector.open-telemetry:4318/v1/traces`.  
  This is the URL of the OpenTelemetry (OTLP protocol) trace collector which can be used by your application to send trace data to the platform.
- `config.server.url`, for example `http://config-server.config-server.svc.cluster.local:8080`.  
  This is the URL of the Spring Config Server provided by the platform.
- `liquibase.datasource.username`, for example set to the key `db.username` in secret `admin-liquibasedb-secrets`.  
  This sets the (admin) user that should be used to run Liquibase, if used in your service.
- `liquibase.datasource.password`, for example set to the key `db.password` in secret `admin-liquibasedb-secrets`.  
  This sets the (admin) user's password that should be used to run Liquibase, if used in your service.
- `spring.datasource.username`, for example set to the key `db.username` in secret `customer32-db-secrets`.  
  This sets the (regular) user for your application to use to connect to the database (if you use JPA or JDBC in your application).
- `spring.datasource.password`:, for example set to the key `db.password` in secret `customer32-db-secrets`.  
  This sets the (regular) user's password for your application to use to connect to the database (if you use JPA or JDBC in your application).
- `DB_SERVICE`, for example set to the key `db.service` in secret `customer32-db-secrets`.  
  This sets the database service name (the TNS name) for your application to use to connect to the database (if you use JPA or JDBC in your application).
- `spring.datasource.url`, for example `jdbc:oracle:thin:@$(DB_SERVICE)?TNS_ADMIN=/oracle/tnsadmin`.  
  This sets the data source URL for your application to use to connect to the database (if you use JPA or JDBC in your application).
- `CONNECT_STRING`, for example `jdbc:oracle:thin:@$(DB_SERVICE)?TNS_ADMIN=/oracle/tnsadmin`.  
  This sets the data source URL for your application to use to connect to the database (if you use JPA or JDBC in your application).
