+++
archetype = "home"
title = "Transactional Event Queues"
+++

[Oracle Transactional Event Queues (TxEventQ)](https://www.oracle.com/database/advanced-queuing/) is a messaging platform built into Oracle Database that combines the best features of messaging and pub/sub systems. TxEventQ was introduced as a rebranding of AQ Sharded Queues in Oracle Database 21c, evolving from the Advanced Queuing (AQ) technology that has been part of Oracle Database since version 8.0. TxEventQ continues to evolve in Oracle Database 23ai, with [Kafka Java APIs](https://github.com/oracle/okafka), Oracle REST Data Services (ORDS) integration, and many more features and integrations.

TxEventQ is designed for high-throughput, reliable messaging in event-driven microservices and workflow applications. It supports multiple publishers and consumers, exactly-once delivery, and robust event streaming capabilities. On an 8-node Oracle Real Application Clusters (RAC) database, TxEventQ can handle approximately 1 million messages per second, demonstrating its scalability.

TxEventQ differs from traditional AQ (now referred to as AQ Classic Queues) in several ways:

1. Performance: TxEventQ is designed for higher throughput and scalability.

2. Architecture: TxEventQ uses a partitioned implementation with multiple event streams per queue, while AQ is a disk-based implementation for simpler workflow use cases.

3. Enhanced interoperability with Apache Kafka, JMS, Spring Boot, ORDS, and other software systems.

Key features of Oracle Database Transactional Event Queues include:

1. Transactional messaging: Enqueues and dequeues are automatically committed along with other database operations, eliminating the need for two-phase commits.

2. Exactly once message delivery.

3. Strict ordering of messages within queue partitions.

4. Retention of messages for a specified time after consumption by subscribers.

5. Capability to query message queues and their metadata by standard SQL.

6. Transactional outbox support: This simplifies event-driven application development for microservices.

For developers, TxEventQ can be integrated into modern application development environments using Oracle Database. It's particularly useful in microservices architectures and event-driven applications where high-throughput, reliable messaging is crucial. The Kafka-compatible Java APIs allow developers to use existing Kafka code with minimal changes, simply by updating the broker address and using Oracle-specific versions of KafkaProducer and KafkaConsumer.

Oracle Database Transactional Event Queues are free to use with Oracle Database in any deployment, including Oracle Database Free.

Citations:
1. [Oracle Database Transactional Event Queues homepage](https://www.oracle.com/database/advanced-queuing/)
2. [Transactional Event Queue Documentation for Oracle Database 23ai](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/aq-introduction.html)
3. [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka)
