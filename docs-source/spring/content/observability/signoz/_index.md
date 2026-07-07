---
title: "SigNoz"
description: "Observability for Spring Boot applications with the Oracle Backend for Microservices and AI"
keywords: "observability metrics signoz spring springboot microservices development oracle backend"
resources:
  - name: obaas-signoz-ui
    src: "obaas-signoz-ui.png"
    title: "SigNoz UI"
  - name: db-dashboard
    src: "db-dashboard.png"
    title: "Oracle Database Dashboard"
  - name: spring-boot-observability-dashboard
    src: "spring-boot-observability-dashboard.png"
    title: "Spring Boot Observability Dashboard"
  - name: spring-boot-stats-dashboard
    src: "spring-boot-stats-dashboard.png"
    title: "Spring Boot Statistics Dashboard"
  - name: kube-state-metrics-dashboard
    src: "kube-state-metrics-dashboard.png"
    title: "Kube State Metrics Dashboard"
  - name: observability-overview
    src: "observability-overview.png"
    title: "Observability Overview"
  - name: apache-apisix-dashboard
    src: "apache-apisix-dashboard.png"
    title: "Apache APISIX Observability Dashboard"
  - name: service-list
    src: "service-list.png"
    title: "Service List"
  - name: service-metrics
    src: "service-metrics.png"
    title: "Service Metrics"
  - name: signoz-logs
    src: "signoz-logs.png"
    title: "SigNoz Logs"
  - name: signoz-logs-details
    src: "signoz-logs-details.png"
    title: "SigNoz Log Details"
  - name: signoz-traces
    src: "signoz-traces.png"
    title: "SigNoz Traces"
  - name: signoz-traces-details
    src: "signoz-traces-details.png"
    title: "SigNoz Trace Details"
---

Oracle Backend for Microservices and AI provides built-in platform services to collect and visualize metrics, logs and traces from system and application workloads.

On this page, you will find the following topics:

- [Overview](#overview)
- [How to access SigNoz](#how-to-access-signoz)
- [Metrics](#metrics)
- [Logs](#logs)
- [Traces](#traces)
- [Pre-installed dashboards](#pre-installed-dashboards)
  - [Spring Boot Observability](#spring-boot-observability)
  - [Spring Boot Statistics](#spring-boot-statistics)
  - [Oracle Database Dashboard](#oracle-database-dashboard)
  - [Kube State Metrics Dashboard](#kube-state-metrics-dashboard)
  - [Apache APISIX Dashboard](#apache-apisix-dashboard)
- [Configure applications for SigNoz Observability](#configure-applications-for-signoz-observability)
  - [Configure OpenTelemetry and Micrometer](#configure-opentelemetry-and-micrometer)
  - [Configure Datasource Observability](#configure-datasource-observability)
  - [Configure Spring Boot Actuator](#configure-spring-boot-actuator)

## Overview

Oracle Backend for Microservices and AI includes SigNoz which is a observability platform to collect and provide access to logs. metrics and traces for the platform itself and for your applications.

The diagram below provides an overview of the SigNoz:

<!-- spellchecker-disable -->

{{< img name="observability-overview" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

In the diagram above:

- You may deploy applications into the platform and can either send the metrics, logs and traces to SigNoz OpenTelemetry collector or configure annotations on the application pod fo SigNoz to scrape metrics endpoints from the application pod directly. Similarly traces can be generated and sent to the SigNoz OpenTelemetry collector using the OpenTelemetry SDK. Please refer to [OpenTelemetry Collector - architecture and configuration guide](https://signoz.io/blog/opentelemetry-collector-complete-guide/) for details.
- The [Oracle Database Exporter](https://github.com/oracle/oracle-db-appdev-monitoring) and Kube State Metrics are pre-installed and SigNoz is configured to collect metrics from them.

- SigNoz populated with a set of dashboards (some of them are described below).

## How to access SigNoz

1. Get the _admin_ email and password for SigNoz

   ```shell
   kubectl -n observability get secret signoz-authn -o jsonpath='{.data.email}' | base64 -d
   kubectl -n observability get secret signoz-authn -o jsonpath='{.data.password}' | base64 -d
   ```

2. Expose the SigNoz user interface (UI) using this command:

   ```shell
   kubectl -n observability port-forward svc/obaas-signoz-frontend 3301:3301
   ```

3. Open [SigNoz Login](http://localhost:3301/login) in a browser and login with the _admin_ email and the password you have retrieved.

   <!-- spellchecker-disable -->

   {{< img name="obaas-signoz-ui" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

## Metrics

To access metrics in SigNoz, click on _Services_ in the menu to see the list of applications.

<!-- spellchecker-disable -->

{{< img name="service-list" size="large" lazy=false >}}

<!-- spellchecker-enable -->

Click on any of the services, to see its metrics in a dashboard.

<!-- spellchecker-disable -->

{{< img name="service-metrics" size="large" lazy=false >}}

<!-- spellchecker-enable -->

## Logs

To access logs in SigNoz, click on _Logs_ in the menu to access the Log Explorer where logs for all the applications and platform services can be accessed.

<!-- spellchecker-disable -->

{{< img name="signoz-logs" size="large" lazy=false >}}

<!-- spellchecker-enable -->

Logs can be filtered based on Namespaces, Deployments, Pods etc. Clicking on any log line will show more details regarding a log event.

<!-- spellchecker-disable -->

{{< img name="signoz-logs-details" size="large" lazy=false >}}

<!-- spellchecker-enable -->

## Traces

To access Traces in SigNoz, click on _Traces_ in the menu to access the Traces view where all trace events can be accessed.

<!-- spellchecker-disable -->

{{< img name="signoz-traces" size="large" lazy=false >}}

<!-- spellchecker-enable -->

Traces can be filtered based on Service, HTTP Routes etc. Click on a trace to see its details.

<!-- spellchecker-disable -->

{{< img name="signoz-traces-details" size="large" lazy=false >}}

<!-- spellchecker-enable -->

Logs for a trace event can directly be accessed using the _Go to related logs_ link.

## Pre-installed dashboards

The following dashboards are pre-installed in SigNoz:

### Spring Boot Observability

This dashboard provides details of one or more Spring Boot applications including the following:

- The number of HTTP requests received by the application
- A breakdown of which URL paths requests were received for
- The average duration of requests by path
- The number of exceptions encountered by the application
- Details of 2xx (that is, successful) and 5xx (that is, exceptions) requests
- The request rate per second over time, by path
- Log messages from the service

You may adjust the time period and to drill down into issues, and search the logs for particular messages. This dashboard is designed for Spring Boot 3.x applications. Some features may work for Spring Boot 2.x applications.

Here is an example of this dashboard displaying data for a simple application:

<!-- spellchecker-disable -->

{{< img name="spring-boot-observability-dashboard" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Spring Boot Statistics

This dashboard provides more in-depth information about services including the following:

- JVM statistic like heap and non-heap memory usage, and details of garbage collection
- Load average and open files
- Database connection pool statistics (for HikariCP)
- HTTP request statistics
- Logging (logback) statistics

You may adjust the time period and to drill down into issues, and search the logs for particular messages. This dashboard is designed for Spring Boot 3.x applications. Some features may work for Spring Boot 2.x applications.

Here is an example of this dashboard displaying data for a simple application:

<!-- spellchecker-disable -->

{{< img name="spring-boot-stats-dashboard" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Oracle Database Dashboard

This dashboard provides details about the Oracle Database including:

- SGA and PGA size
- Active sessions
- User commits
- Execute count
- CPU count and platform
- Top SQL
- Wait time statistics by class

Here is an example of this dashboard:

<!-- spellchecker-disable -->

{{< img name="db-dashboard" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Kube State Metrics Dashboard

This dashboard provides details of the Kubernetes cluster including:

- Pod capacity and requests for CPU and memory
- Node availability
- Deployment, Stateful Set, Pod, Job and Container statistics
- Details of horizontal pod autoscalers
- Details of persistent volume claims

Here is an example of this dashboard:

<!-- spellchecker-disable -->

{{< img name="kube-state-metrics-dashboard" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Apache APISIX Dashboard

This dashboard provides details of the APISIX API Gateway including:

- Total Requests
- NGINX Connection State
- Etcd modifications

Here is an example of this dashboard:

<!-- spellchecker-disable -->

{{< img name="apache-apisix-dashboard" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

## Configure applications for SigNoz Observability

In order for SigNoz to be able to collect logs, metrics and traces from applications, some configurations are required to be added.

### Configure OpenTelemetry and Micrometer

[OpenTelemetry zero-code instrumentation](https://opentelemetry.io/docs/zero-code/java/spring-boot-starter/getting-started/) enables adding observability to Spring Boot based applications without changing any code. Similarly [Micrometer](https://docs.micrometer.io/micrometer/reference/observation/projects.html) enables instrumentation of JVM based applications and can be configured using Spring Boot starters.

```xml
<dependencies>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-core</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-tracing-bridge-otel</artifactId>
        <exclusions>
            <exclusion>
                <groupId>io.opentelemetry.instrumentation</groupId>
                <artifactId>opentelemetry-instrumentation-api-incubator</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-exporter-otlp</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-tracing</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry.instrumentation</groupId>
        <artifactId>opentelemetry-spring-boot-starter</artifactId>
    </dependency>
    <dependency>
        <groupId>net.ttddyy.observation</groupId>
        <artifactId>datasource-micrometer-spring-boot</artifactId>
    </dependency>
    <dependency>
        <groupId>com.oracle.database.spring</groupId>
        <artifactId>oracle-spring-boot-starter-ucp</artifactId>
        <type>pom</type>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry.instrumentation</groupId>
        <artifactId>opentelemetry-oracle-ucp-11.2</artifactId>
        <version>2.13.1-alpha</version>
    </dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.opentelemetry.instrumentation</groupId>
            <artifactId>opentelemetry-instrumentation-bom</artifactId>
            <version>2.13.1</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-tracing-bom</artifactId>
            <version>${micrometer-tracing.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### Configure Datasource Observability

[datasource-micrometer](https://github.com/jdbc-observations/datasource-micrometer) and [Oracle Universal Connection Pool Instrumentation](https://github.com/open-telemetry/opentelemetry-java-instrumentation/tree/main/instrumentation/oracle-ucp-11.2) can be configured to enable observability for Database connections and queries.

```xml
<dependencies>
    <dependency>
        <groupId>net.ttddyy.observation</groupId>
        <artifactId>datasource-micrometer-spring-boot</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry.instrumentation</groupId>
        <artifactId>opentelemetry-oracle-ucp-11.2</artifactId>
        <version>2.13.1-alpha</version>
    </dependency>
</dependencies>
```

### Configure Spring Boot Actuator

When you deploy an application with Oracle Backend for Microservices and AI CLI or Visual Code Extension, provided you included the Spring Actuator in your application, SigNoz will automatically find your application (using the annotations) and start collecting metrics. These metrics will be included in both the Spring Boot Observability dashboard and the Spring Boot Statistic dashboard automatically.

To include the Actuator in your application, add the following dependencies to your Maven POM or equivalent:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

You must also add the configuration similar to one given below, after customizing it for your application, to your Spring `application.yaml`

```yaml
spring:
  threads:
    virtual:
      enabled: true
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.OracleDialect
        format_sql: true
    show-sql: true

eureka:
  instance:
    hostname: ${spring.application.name}
    preferIpAddress: true
  client:
    service-url:
      defaultZone: ${eureka.service-url}
    fetch-registry: true
    register-with-eureka: true
    enabled: true

management:
  endpoint:
    health:
      show-details: always
      show-components: always
  endpoints:
    web:
      exposure:
        include: "*"
  metrics:
    tags:
      application: ${spring.application.name}
    distribution:
      percentiles[http.server.requests]: 0.5, 0.90, 0.95, 0.99
      percentiles-histogram[http.server.requests]: true
      slo[http.server.requests]: 100ms, 250ms, 500ms, 1s, 2s, 5s, 10s, 30s
      percentiles[http.client.requests]: 0.5, 0.90, 0.95, 0.99
      percentiles-histogram[http.client.requests]: true
      slo[http.client.requests]: 100ms, 250ms, 500ms, 1s, 2s, 5s, 10s, 30s
  health:
    probes:
      enabled: true
  tracing:
    sampling:
      probability: 1.0
  info:
    os:
      enabled: true
    env:
      enabled: true
    java:
      enabled: true
  observations:
    key-values:
      app: ${spring.application.name}

logging:
  level:
    root: INFO
    com.example: INFO
    org.springframework.web.filter.AbstractRequestLoggingFilter: INFO

jdbc:
  datasource-proxy:
    query:
      enable-logging: true
      log-level: INFO
    include-parameter-values: true
```

The Oracle Backend for Microservices and AI platform adds following annotations to your application pods for SigNoz to start scraping the actuator endpoint for metrics.

```yaml
signoz.io/path: /actuator/prometheus
signoz.io/port: "8080"
signoz.io/scrape: "true"
```

It also adds the `OTEL_EXPORTER_OTLP_ENDPOINT` to pod environment variables for the OpenTelemetry instrumentation libraries to access the the OpenTelemtry collector of SigNoz.

```yaml
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://obaas-signoz-otel-collector.observability:4318
```
