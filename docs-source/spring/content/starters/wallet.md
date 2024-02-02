---
title: "Oracle Spring Boot Starter for Wallet"
description: "Spring Boot Starters for Oracle Database Wallet"
keywords: "starter wallet mtls oracle database springboot spring development microservices development"
---

This starter provides support for wallet-based authentication for Oracle Database connections.  It depends
on the UCP starter.

To add this starter to your project, add this Maven dependency:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-wallet</artifactId>
    <version>23.4.0</version>
</dependency>
```

For Gradle projects, add this dependency:

```gradle
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-wallet:23.4.0'
```

You need to provide the wallet to your application.  You can specify the location in the `spring.datasource.url`
as shown in the following example.

```text
jdbc:oracle:thin:@mydb_tp?TNS_ADMIN=/oracle/tnsadmin
```

Note that the location specified in the `sqlnet.ora` must match the actual location of the file.

If your service is deployed in Kubernetes, then the wallet should be placed in a Kubernetes secret which
is mounted into the pod at the location specified by the `TNS_ADMIN` parameter in the URL.

