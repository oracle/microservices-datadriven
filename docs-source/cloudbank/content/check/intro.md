+++
archetype = "page"
title = "Introduction"
weight = 1
+++


This module walks you through the steps to build Spring Boot microservices that use Java Message Service (JMS) to send and receive asynchronous messages using Transactional Event Queues in the Oracle Database.  This service will also use service discovery (OpenFeign) to look up and use the previously built Account service. In this lab, we will extend the Account microservice built in the previous lab, build a new "Check Processing" microservice and another "Test Runner" microservice to help with testing.

Estimated Time: 20 minutes

### Objectives

In this lab, you will:

* Create new Spring Boot projects in your IDE
* Plan your queues and message formats
* Use Spring JMS to allow your microservice to use JMS Transactional Event Queues in the Oracle database
* Use OpenFeign to allow the Check Processing service to discover and use the Account service
* Create a "Test Runner" service to simulate the sending of messages
* Deploy your microservices into the backend

### Prerequisites (Optional)

This module assumes you have:

* An Oracle Cloud account
* All previous labs successfully completed

