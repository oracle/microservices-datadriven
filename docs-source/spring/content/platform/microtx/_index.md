---
title: "MicroTx"
description: "Transaction coordination and data consistency across microservices using MicroTx in Oracle Backend for Spring Boot and Microservices"
keywords: "transactions xz lra tcc microtx consistency coordination orchestration springboot spring development microservices development oracle backend"
---

[Oracle Transaction Manager for Microservices](https://www.oracle.com/database/transaction-manager-for-microservices/), also known as "MicroTx", simplifies application development and operations by enabling distributed transactions to ensure consistency across microservices deployed in Kubernetes.

Oracle Backend for Spring Boot and Microservices includes the free version of MicroTx, which has all of the functionality of the commercial version, but limits the number of transactions and only persists data in memory.  It is recommended for evaluations and application development purposes.

MicroTx supports the following consistency models:

- Extended Architecture (XA)
- Long Running Actions (LRA)
- Try-Confirm/Cancel (TCC)

The [CloudBank sample application](../../#learn-more-try-it-out-with-cloudbank) includes a "Transfer" service which demonstrates how to use MicroTx to implement the Saga pattern using the Eclipse Microprofile Long Running Actions specification. 

To use MicroTx in your Spring Boot applications, include the following dependency in your `pom.xml` or equivalent:

```
<dependency>
    <groupId>com.oracle.microtx.lra</groupId>
    <artifactId>microtx-lra-spring-boot-starter-3x</artifactId>
    <version>23.4.1</version>
</dependency>
```

Add the following configuration to your Spring application configuration. The variables in this configuration are automatically injected to your deployment and pods when you use the Oracle Backend for Spring Boot and Microservices CLI or the Visual Studio Code Extension to deploy your application. For example:

```
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

## Upgrading to the commercial version

If you have licensed Oracle Transaction Manager for Microservices Enterprise Edition, please see the [documentation](https://docs.oracle.com/en/database/oracle/transaction-manager-for-microservices/23.4.1/index.html) for details of how to install and configure MicroTx.  Oracle recommnds that you perform a new installation rather than attempting to upgrade the provided MicroTx Free installation to the commercial version.