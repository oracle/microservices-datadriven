---
title: "Tracing"
linkTitle: Tracing
description: "Tracing with Open Telemetry for Spring Boot applications with the Oracle Backend for Spring Boot and Microservices"
keywords: "observability tracing opentelemetry spring springboot microservices development oracle backend"
resources:
  - name: obaas-jaeger-ui
    src: "obaas-jaeger-ui.png"
    title: "Jaeger UI"
  - name: obaas-jaeger-customer-tracing
    src: "obaas-jaeger-customer-tracing.png"
    title: "Jaeger Customer Tracing"
  - name: obaas-jaeger-customer-trace-details
    src: "obaas-jaeger-customer-trace-details.png"
    title: "Jaeger Customer Tracing Details"

weight: 1
draft: false
---

## Overview

In a distributed system, it’s expected that occasional errors are bound to happen when serving requests. A central observability platform helps by capturing application traces/logs and provides an interface to query for a specific request. OpenTelemetry helps in standardizing the process of capturing and exporting telemetry data.

OpenTelemetry (Otel) is a collection of standardized vendor-agnostic tools, APIs, and SDKs. It’s a CNCF incubating project and is a merger of the OpenTracing and OpenCensus projects.

OpenTracing is a vendor-neutral API for sending telemetry data over to an observability backend. The OpenCensus project provides a set of language-specific libraries that developers can use to instrument their code and send it to any supported backends. Otel uses the same concept of trace and span to represent the request flow across microservices as used by its predecessor projects.

OpenTelemetry allows us to instrument, generate, and collect telemetry data, which helps in analyzing application behavior or performance. Telemetry data can include logs, metrics, and traces. We can either automatically or manually instrument the code for HTTP, DB calls, and more.

## How to enable tracing for your applications

To enable tracing for your application you must include the following dependencies to your Maven POM or equivalent.

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
  <groupId>io.opentelemetry</groupId>
  <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-tracing</artifactId>
</dependency>
```

If you want to enable tracing for your database calls you must include the following dependency too. You can find the latest version [here](https://mvnrepository.com/artifact/net.ttddyy.observation/datasource-micrometer-spring-boot).

```xml
<dependency>
  <groupId>net.ttddyy.observation</groupId>
  <artifactId>datasource-micrometer-spring-boot</artifactId>
  <version>1.0.3</version>
</dependency>
```


## View Application Traces in Jaeger Web User Interface

Jaeger is a distributed tracing system used for monitoring and troubleshooting Microservices. For more information on Jaeger, see the [Jaeger website](https://www.jaegertracing.io/).

1. Expose the Jaeger web user interface using this command:

    ```shell
    kubectl -n observability port-forward svc/jaegertracing-query 16686:16686
    ```

2. Open the Jaeger web user interface URL: <http://localhost:16686>

    <!-- spellchecker-disable -->
    {{< img name="obaas-jaeger-ui" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Jaeger web user interface, click the **Search** tab to find tracings using various search criteria. For example, to find
   traces for the customer Microservice included in the Sample Applications:

    a. If you deployed the [Sample Applications](../../sample-apps), exposing the customer service through the Apache APISIX Gateway and
	   called it at least once, you can find traces for it in Jaeger.
	   
    b. Select the **Service** `customer` and the **Operation** `/api/v1/customers` .
	
    c. Click on **Find Traces**. Several traces appear (one for each time that you invoked the service).
        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-tracing" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    d. Click on any one of them to view the trace that includes multiple services and extends into Oracle Database and Oracle
	   Advanced Queuing. For example:
        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-trace-details" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

