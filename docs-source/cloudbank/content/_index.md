+++
archetype = "home"
title = "CloudBank"
+++

Welcome to CloudBank - an on-demand, self-paced learning resource you can use
to learn about developing microservices with [Spring Boot](https://spring.io/projects/spring-boot) 
and deploying, running and managing them with [Oracle Backend for Spring Boot and Microservices](https://bit.ly/oraclespringboot).

You can follow through from beginning to end, or you can start at any module that you are interested in.

### What you will need

To complete the modules you will somewhere to run Oracle Backend for Spring Boot and Microservices.
The instructions in the Module 1 provide three alternatives: 

- Locally in a container - you will need a container platform like Docker Desktop, Rancher Desktop, Podman Desktop or similar.
  This option is recommended only if you have at least 64GB of RAM.  With less memory this option will probably be too slow.
- In a compute instance in an Oracle Cloud Free Tier account.  You can sign up for an [Oracle Cloud Free Tier account here](https://signup.cloud.oracle.com/).
  This account will include enough free credits to run CloudBank.
- In a commercial Oracle Cloud tenancy.  If you have a commercial tenancy with sufficient capacity and
  privileges, you can run the full production-sized installation.  This can be installed from the OCI Marketplace
  using the instructions in Module 1.  Check the instructions for a more detailed list of requirements.

Regardless of which option you choose, the remainder of the modules will be virtually identical.  

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
  with a *synchronous* API implemented as REST endpoints using Spring Web MVC, and how to
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
* **Module 6: Building the CloudBank AI Assistant using Spring AI**
  This modules introduces [Spring AI](https://github.com/spring-projects/spring-ai)
  and explores how it can be used to build a CloudBank AI Assistant (chatbot) that will
  allow users to interact with CloudBank using a chat-based interface.
  In this module, you will learn about Retrieval Augmented Generation, Vector
  Database and AI Agents.
* **Module 7: Deploying the full CloudBank Application using the CLI**  
  In this module, you will learn how to deploy the full CloudBank application
  to Oracle Backend for Spring Boot and Microservices using the CLI.
  If you prefer to use an IDE, skip this module and go to module 6 instead.
* **Module 8: Deploying the full CloudBank Application using the IDE plugins**  
  In this module, you will learn how to deploy the full CloudBank application
  to Oracle Backend for Spring Boot and Microservices using one of the
  IDE plugins - for Visual Studio Code or IntelliJ.  
* **Module 9: Explore the Backend Platform**  
  This module will take you on a guided tour through the Oracle Backend for
  Spring Boot and Microservices platform. You will learn about the platform
  services and observability tools that are provided out-of-the-box.
* **Module 10: Cleanup**
  This module demonstrates how to clean up any resources created when
  you provisioned an instance of Oracle Backend for Spring Boot and Microservices
  on Oracle Cloud Infrastructure (OCI) or on your local machine using Docker Compose.  