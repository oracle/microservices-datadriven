+++
archetype = "chapter"
title = "Getting Started"
weight = 1
+++

Oracle Database Transactional Event Queues (TxEventQ) is a high-performance messaging platform built into Oracle Database, designed for application workflows, microservices, and event-driven architectures. This guide will provide you with a thorough understanding of Oracle Database Transactional Event Queues, enabling you to leverage its powerful features for building robust, scalable, and event-driven applications.

This module will cover the following key topics:

## Core Concepts
- Queues and topics
- Enqueue/Dequeue vs. Publish/Subscribe models
- Payload types: RAW, ADT, JSON, and JMS

## Queue Management
- Necessary grants, roles, and permissions for using queues
- Creating, starting, stopping, and dropping queues/topics in various languages
- SQLcl examples for queue operations

## Message Operations
- Producing and consuming messages
- Message expiry and exception queues
- Message Delay
- Message Priority

## Advanced Features
- Transactional messaging: Combining messaging and DML in a single transaction
- Message propagation between queues and databases
- Exception queues and error handling
