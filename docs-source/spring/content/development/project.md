---
title: "Project Structure"
description: "How to structure your Spring Boot application for deployment in Oracle Backend for Spring Boot and Microservices"
keywords: "spring springboot microservices development oracle backend"
---

To take advantage of the built-in platform services, Oracle recommends using the following project structure.

Recommended versions:

* Spring Boot 3.3.x
* Spring Cloud 2023.x.x
* Java 21 (or 17)

Table of Contents:

* [Dependencies](#dependencies)
* [Spring Application Configuration](#spring-application-configuration)
  * [Data Sources](#data-sources)
  * [Liquibase](#liquibase)
  * [Oracle Transaction Manager for Microservices](#oracle-transaction-manager-for-microservices)
  * [Spring Config Server](#spring-config-server)
  * [Tracing](#tracing)

## Dependencies

Oracle recommends adding the following dependencies to your application so that it can take advantage of the built-in platform services. For example:

```xml
<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <java.version>21</java.version>
    <spring.boot.dependencies.version>3.3.1</spring.boot.dependencies.version>
    <spring-cloud.version>2023.0.2</spring-cloud.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>${spring.boot.dependencies.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>${spring-cloud.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>    
```

## Spring Application Configuration

Oracle recommends the following configuration in order for the application to access the built-in services, including the Spring Boot Eureka Service Registry and the observability tools:

```yaml
spring:
  application:
    name: account

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
  endpoints:
    web:
      exposure:
        include: "*"
  metrics:
    tags:
      application: ${spring.application.name}
```

The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application.

### Data Sources

If your application uses an Oracle database as data source, then add the following to the 'pom.xml'. For more information about the [Oracle Spring Boot Starters](../starters/_index).

```xml
<dependency>
  <groupId>com.oracle.database.spring</groupId>
  <artifactId>oracle-spring-boot-starter-ucp</artifactId>
  <version>23.4.0</version>
  <type>pom</type>
</dependency>
```

If the database requires a Wallet to access the database you must add the following to the `pom.xml` file:

```xml
<dependency>
  <groupId>com.oracle.database.spring</groupId>
  <artifactId>oracle-spring-boot-starter-wallet</artifactId>
  <version>23.4.0</version>
  <type>pom</type>
</dependency>
```

 Add the following to application configuration. Note that this example shows Java Persistence API (JPA). If you are using JDBC you should use the appropriate configuration. For example:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.OracleDialect
        format_sql: false
    show-sql: false

  datasource:
    url: ${spring.datasource.url}
    username: ${spring.datasource.username}
    password: ${spring.datasource.password}
    driver-class-name: oracle.jdbc.OracleDriver
    type: oracle.ucp.jdbc.PoolDataSource
    oracleucp:
      connection-factory-class-name: oracle.jdbc.pool.OracleDataSource
      connection-pool-name: AccountConnectionPool
      initial-pool-size: 15
      min-pool-size: 10
      max-pool-size: 30
```

The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application.

### Liquibase

If you are using Liquibase to manage your database schema and data, then you should add the following dependency:

```xml
<properties>
    <liquibase.version>4.28.0</liquibase.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.liquibase</groupId>
        <artifactId>liquibase-core</artifactId>
        <version>${liquibase.version}</version>
    </dependency>
</dependencies>
```

Add the following configuration to your Spring application configuration:

```yaml
spring:  
  liquibase:
    change-log: classpath:db/changelog/controller.yaml
    url: ${spring.datasource.url}
    user: ${liquibase.datasource.username}
    password: ${liquibase.datasource.password}
    enabled: ${LIQUIBASE_ENABLED:true}
```

The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application. When you use the `deploy` command, you must specify the `liquibase-db` parameter and provide a user with sufficient privileges. Generally this will be permissions to create and alter users and to grant roles and privileges.  If your service uses Java Messaging Service (JMS), this use may also need execute permission on `dbms.aq_adm`, `dbms.aq_in` and `dbms.aq_jms`.

### Oracle Transaction Manager for Microservices

If you are using Oracle Transaction Manager for Microservices (MicroTx) to manage data consistency across microservices data stores, then add the following dependency:

```xml
<dependency>
    <groupId>com.oracle.microtx.lra</groupId>
    <artifactId>microtx-lra-spring-boot-starter</artifactId>
    <version>24.2.1</version>
</dependency>
```

Add the following configuration to your Spring application configuration. The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI or the Visual Studio Code Extension to deploy your application. For example:

```yaml
spring:
  microtx:
    lra:
      coordinator-url: ${MP_LRA_COORDINATOR_URL}
      propagation-active: true
      headers-propagation-prefix: "{x-b3-, oracle-tmm-, authorization, refresh-}"   

lra:
  coordinator:
    url: ${MP_LRA_COORDINATOR_URL}
```

### Spring Config Server

If you are using Spring Config Server to manage configurations, then add the following dependency:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
```

Add the following configuration to your Spring application configuration. The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI or the Visual Studio Code Extension to deploy your application. For example:

```yaml
spring:
  application:
    name: <application name>
  config:
    import: optional:configserver:${config.server.url} 

  cloud:
     config:
       label: <optional>
       profile: <optional>
       username: <A user with the role ROLE_USER>
       password: <password>
```

## Tracing

### Application Tracing

To enable Open Telemetry (OTEL) tracing you need to add the following dependencies to the `pom/xml` file.

```xml
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

In addition add the following to the application configuration. The variable in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI or the Visual Studio Code Extension to deploy your application. For example:

```yaml
management:
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
  otlp:
    tracing:
      endpoint: ${otel.exporter.otlp.endpoint}
```

### Database tracing

To get tracing for the database calls you need to add the following dependency to the `po.xml` file:

```xml
<dependency>
    <groupId>net.ttddyy.observation</groupId>
    <artifactId>datasource-micrometer-spring-boot</artifactId>
    <version>1.0.3</version>
</dependency>
```
