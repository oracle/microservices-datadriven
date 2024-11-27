+++
archetype = "chapter"
title = "Kafka APIs"
weight = 2
+++

Oracle Database Transactional Event Queues (TxEventQ) offers comprehensive integration with Apache Kafka, providing developers with a powerful and flexible messaging platform. This module explores the synergy between TxEventQ and Kafka, covering essential concepts and practical implementations. In this module, we'll refer to _queues_ as _topics_ when working with TxEventQ and Kafka.

Throughout this module, we'll explore practical examples using Java code and SQLcl commands to demonstrate:

- Creating and managing topics using Kafka APIs with TxEventQ
- Producing and consuming messages using Kafka client libraries
- Implementing transactional messaging with database operations
- Utilizing Kafka REST APIs for TxEventQ message handling
- Configuring and using Kafka connectors for TxEventQ

By the end of this module, you'll have a comprehensive understanding of how to leverage Oracle TxEventQ's Kafka compatibility features to build robust, scalable, and event-driven applications.

## Kafka and TxEventQ Concepts

TxEventQ and Kafka share several common architectural concepts, making it easier for developers familiar with Kafka to work with TxEventQ. Key concepts include:

- Topics: Logical channels for message streams
- Partitions: Subdivisions of topics for parallel processing
- Offsets: Unique identifiers for messages within a partition
- Hashing keys: Deterministic message routing within partitions
- Brokers: Oracle Database servers hosting topics and partitions
- Ordering: TxEventQ maintains message ordering within partitions, similar to Kafka. Developers can implement partition-level subscribers to ensure ordered message processing.

## Developing with Kafka APIs on TxEventQ

TxEventQ supports Kafka Java APIs through the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka), allowing developers to leverage existing Kafka knowledge developing against TxEventQ. Key operations include:

- Authenticating to Oracle Database with Kafka APIs
- Creating topics and partitions using Kafka Admin
- Producing messages to topics with Kafka Producers
- Consuming messages from topics using Kafka Consumers

## Kafka Connectors

Oracle offers a Kafka connector for TxeventQ, enabling seamless integration of messages from both platforms. These connectors allow:

- Syncing messages from Kafka topics to TxEventQ queues
- Sourcing messages from TxEventQ for consumption by Kafka clients

## Transactional Messaging

One of TxEventQ's unique features is its ability to combine messaging and database operations within a single transaction. This capability, often referred to as the "transactional outbox" pattern, ensures data consistency across microservices. We'll explore this pattern through the Kafka Java Client for Oracle Database Transactional Event Queues.
