---
title: "Project Structure"
---

To take advantage of the built-in platform services, Oracle recommends
using the following project structure.

Recommended versions:

* Spring Boot 3.1.5
* Spring Cloud 2022.0.4
* Java 17 or 21

### Dependencies

Oracle recommends adding the following dependencies to your application so that it
can take advantage of the built-in platform services:

```xml
<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <java.version>17</java.version>
    <spring.boot.dependencies.version>3.1.5</spring.boot.dependencies.version>
    <spring-cloud.version>2022.0.4</spring-cloud.version>
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

### Spring Application Configuration

Oracle recommends the following configuration in order for the application access to
use the built-in services, including the Spring Boot Eureka Service Registry and the
observability tools:

```yaml
spring:
  application:
    name: account
  zipkin:
    base-url: ${zipkin.base-url}

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

The variables in this configuration are automatically injected to your deployment
and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application. 

#### Data Sources

If your application uses a data source, then add the following configuration.  Note that this
example shows Java Persistence API (JPA), if you are using JDBC you should use the appropriate configuration.

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

The variables in this configuration are automatically injected to your deployment
and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application. 

#### Liquibase

If you are using Liquibase to manage your database schema and data, then you should
add the following dependency:

```xml
<properties>
    <liquibase.version>4.24.0</liquibase.version>
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

The variables in this configuration are automatically injected to your deployment
and pods when you use the Oracle Backend for Spring Boot and Microservices CLI to deploy your application. 
When you use the `deploy` command, you must specify the `liquibase-db` parameter and
provide a user with sufficient privileges, generally this will be premissions to create and alter
users and to grant roles and privileges.  If your service uses JMS, this use may also
need execute permissions on `dbms.aq_adm`, `dbms.aq_in` and `dbms.aq_jms`.


#### Oracle Transaction Manager for Microservices

If you are using Oracle Transaction Manager for Microservices (MicroTx) to manage
data consistency across microservices data stores, then add the following
dependency:

```xml
<dependency>
     <groupId>com.oracle.microtx.lra</groupId>
     <artifactId>microtx-lra-spring-boot-starter-3x</artifactId>
     <version>23.4.1</version>
</dependency>
```

Add the following configuration to your Spring application configuration:

```yaml
spring:
  microtx:
    lra:
      coordinator-url: http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator
      propagation-active: true
      headers-propagation-prefix: "{x-b3-, oracle-tmm-, authorization, refresh-}"   

lra:
  coordinator:
    url: http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator
```