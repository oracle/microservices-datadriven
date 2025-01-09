+++
archetype = "chapter"
title = "Spring Boot Integration"
weight = 3
+++

Oracle Transactional Event Queues (TxEventQ) features several Spring Boot integrations, allowing application developers to work with TxEventQ using common Spring idioms and starters. This module explores the various integration points and best practices for leveraging TxEventQ within the Spring ecosystem.

## Spring Boot Starter for AQ/JMS

The Oracle Spring Boot Starter for AQ/JMS simplifies the integration of TxEventQ with Spring and JMS. Key features include:

- Automatic configuration of JMS ConnectionFactory
- Support for transactional message processing
- Easy setup with Maven or Gradle dependencies

## Spring Boot Starter for Kafka Java Client for Oracle Database Transactional Event Queues

The Spring Boot Starter for the Kafka Java Client for Oracle Database Transactional Event Queues integrates all necessary dependencies to use TxEventQ with the [Kafka Java API](https://github.com/oracle/okafka) within a Spring Boot application.

## TxEventQ Spring Cloud Stream Binder

[Spring Cloud Stream](https://spring.io/projects/spring-cloud-stream) is a Java framework designed for building event-driven microservices backed by scalable, fault-tolerant messaging systems. The [Oracle Database Transactional Event Queues (TxEventQ) stream binder](https://github.com/oracle/spring-cloud-oracle/tree/main/database/spring-cloud-stream-binder-oracle-txeventq)  implementation enables developers to integrate Oracle's database messaging platform with Spring Cloud Stream. This integration allows you to keep your data within the converged database while benefiting from a functional message interface.