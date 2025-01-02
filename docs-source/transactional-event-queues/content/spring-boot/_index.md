+++
archetype = "chapter"
title = "Spring Boot Integration"
weight = 3
+++

Oracle Transactional Event Queues (TxEventQ) features several Spring Boot integrations, allowing application developers to work with TxEventQ using common Spring idioms and starters. This module explores the various integration points and best practices for leveraging TxEventQ within the Spring ecosystem.

## Spring Boot Starter for AQ/JMS

The Oracle Spring Boot Starter for AQ/JMS simplifies TxEventQ integration with Spring and JMS. Key features include:

- Automatic configuration of JMS ConnectionFactory
- Support for transactional message processing
- Easy setup with Maven or Gradle dependencies

## Spring Boot Starter for Kafka Java Client for Oracle Database Transactional Event Queues

The Kafka Java Client for Oracle Database Transactional Event Queues Spring Boot Starter pulls in all necessary dependencies to work with Transactional Event Queues [Kafka Java API](https://github.com/oracle/okafka) using Spring Boot.

## TxEventQ Spring Cloud Stream Binder

[Spring Cloud Stream](https://spring.io/projects/spring-cloud-stream) is a Java framework designed for building event-driven microservices backed by a scalable, fault-tolerant messaging systems. The [Oracle Database Transactional Event Queues (TxEventQ) stream binder](https://github.com/oracle/spring-cloud-oracle/tree/main/database/spring-cloud-stream-binder-oracle-txeventq) implementation allows developers to leverage Oracle’s database messaging platform within the Spring Cloud Stream ecosystem, all while keeping your data within the converged database.
