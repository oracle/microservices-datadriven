+++
archetype = "home"
title = "CloudBank"
+++

Welcome to CloudBank - an on-demand, self-paced learning resource you can use
to learn about developing microservices with [Spring Boot](https://spring.io/projects/spring-boot) 
and deploying, running and managing them with [Oracle Backend for Spring Boot and Microservices](https://bit.ly/oraclespringboot).

You can follow through from beginning to end, or you can start at any module that you are interested in.

### What you will need

To complete the modules you will need `docker-compose` to run the backend and Oracle Database containers - you
can use Docker Desktop, Rancher Desktop, Podman Desktop or similar. 

You will need a Java SDK and either Maven or Gradle to build your applicaitons. An IDE is not strictly required,
but you will have a better overall experience if you use one.  We recommend Visual Studio Code or IntelliJ.

### Modules

CloudBank contains the following modules:

* **Module 1: Provision the Backend**
  This module guides you through provisioning an instance of the backend using
  Oracle Cloud Infrastructure (OCI) or on your local machine using Docker Compose.
* **Module 2: Preparing your Development Environment**  
  This module guides you through setting up your development environment including
  and IDE and a toolchain to build and test your applications.
* **Module 3: Build the Account Microservice**  
  This module walks you through building your very first microservice using Spring Boot.
  It assumes no prior knowledge of Spring Boot, so its a great place to start if you
  have not used Spring Boot before. This module demonstrates how to build a service
  with a *synchronous* API implmented as REST endpoints using Spring Web MVC, and how to
  store data in Oracle Database using Spring Data JPA.
* **Module 4: Build the Check Processing Microservices**  
  In this module, you will build microservices that use *asynchronous* messaging
  to communicate using Spring JMS and Oracle Transactional Event Queues. It introduces
  service discovery using Eureka Service Registry (part of [Spring Cloud Netflix](https://spring.io/projects/spring-cloud-netflix)) 
  and [Spring Cloud OpenFeign](https://spring.io/projects/spring-cloud-openfeign).
* **Module 5: Manage Saga Transactions across Microservices**  
  This module introduces the Saga pattern, a very important pattern that helps us
  manage data consistency across microservices. We will explore the Long Running
  Action specification, one implementation of the Saga pattern, and then build
  a Transfer microservice that will manage funds transfers using a saga.  
* **Module 6: Deploying the full CloudBank Application using the CLI**  
  In this module, you will learn how to deploy the full CloudBank application
  to Oracle Backend for Spring Boot and Microservices using the CLI.
  If you prefer to use an IDE, skip this module and go to module 6 instead.
* **Module 7: Deploying the full CloudBank Application using the IDE plugins**  
  In this module, you will learn how to deploy the full CloudBank application
  to Oracle Backend for Spring Boot and Microservices using one of the
  IDE plugins - for Visual Studio Code or IntelliJ.  
* **Module 8: Explore the Backend Platform**  
  This module will take you on a guided tour through the Oracle Backend for
  Spring Boot and Microservices platform. You will learn about the platform
  services and observability tools that are provided out-of-the=box
* **Module 9: Cleanup**
  This module demonstrates how to clean up any resources created when
  you provisioned an instance of Oracle Backend for Spring Boot and Microservices
  on Oracle Cloud Infrastructure (OCI) or on your local machine using Docker Compose.  