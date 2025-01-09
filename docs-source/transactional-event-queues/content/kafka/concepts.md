+++
archetype = "page"
title = "Kafka and TxEventQ Concepts"
weight = 1
+++

This section describes the architectural concepts of **Oracle Database Transactional Event Queues** in the context of Apache Kafka APIs. When working with Kafka APIs, we'll refer to _queues_ as _topics_.

* [Kafka Brokers or a Database Server?](#kafka-brokers-or-a-database-server)
* [Topics, Producers, and Consumers](#topics-producers-and-consumers)
* [Partitions and Ordering](#partitions-and-ordering)
  * [Partition Keys](#partition-keys)
  * [Message Offsets](#message-offsets)
  * [Message Commits](#message-commits)


## Kafka Brokers or a Database Server?

When using Oracle Database Transactional Event Queues with Kafka APIs, the database server assumes the role of the Kafka Broker, eliminating the need for additional messaging systems.

Using your database as a message broker allows you to avoid separate, costly servers dedicated to event streaming. These servers typically require domain-specific knowledge to operate, maintain, and upgrade in production deployments.

With a database message broker, your messaging data is co-located with your other data and remains queryable with SQL. This reduces network traffic and data duplication across multiple servers (and their associated costs), while benefiting applications that need access to both event streaming data and its related data.

## Topics, Producers, and Consumers

A topic is a logical channel for message streams, capable of high-throughput messaging. _Producers_ write data to topics, producing messages. _Consumers_ subscribe to topics and poll message data. Each consumer is part of a consumer group, which is a logical grouping of consumers, their subscriptions, and assignments.

With Oracle Database Transactional Event Queues, each topic is backed by a queue table, allowing [transactional messaging](./transactional-messaging.md) and query capabilities. For example, you can query the first five messages from a topic named `my_topic` directly with SQL:

```sql
select * from my_topic
fetch first 5 rows only;
```

When using Kafka APIs for Transactional Event Queues, you may also run database queries as part of consumer and producer workflows.

## Partitions and Ordering

Topics are divided into one or more _partitions_, where each partition is backed by a Transactional Event Queue shard. A partition represents an ordered event stream within the topic. 

Partitions enable parallel message consumption, as multiple consumers in the same consumer group can concurrently poll from the topic. Consumers are assigned one or more partitions depending on the size of the consumer group. Each partition, however, may be assigned to at most one consumer per group. For example, a topic with three partitions can have at most three active consumers per consumer group.

Within a partition, each message is strictly ordered. If each consumer in a consumer group is assigned to only one partition, then the consumers in the group are guaranteed to receive only the ordered stream of messages from their assigned partition. Additionally, this strategy will commonly result in the highest throughput per topic.

### Partition Keys

Partition keys are used to route messages to specific partitions, ensuring the ordering of messages is preserved in the partition. To ensure strict ordering, use a consistent piece of message data as the partition key for each producer record. For example, if you are processing user interactions, the use of the user ID as a partition key will ensure each user's messages are produced to a consistent partition. The user ID is implicitly hashed to produce a consistent partition key.

The use of partition keys is not mandatory: round-robin partition assignment is used if no partition key is provided in the producer record. Round-robin assignment is convenient when there is no specific ordering of messages, or strict ordering is not required.

 > Note that you may directly specify the topic partition when producing a message, instead of relying on key hashing. This is useful when there is no message data suitable for the partition key, or if you require a direct level of control over partitioning.

### Message Offsets

Offsets are used to track the progress of consumers as they consume messages from topics. An offset is an identifier for a specific position in a topic's partition. When a consumer reads a message, it commits the offset to indicate that the message is being processed. Offsets serve as consumer checkpoints and can be used to replay messages. Replay is useful for debugging, reprocessing failed events, or back-filling data.

For example, consumers can be started from the earliest known offset and progress to the newest message, started at the latest known offset, or have their offset moved to a specific point in the partition.

### Message Commits

With Oracle Database Transactional Event Queues, each message operation occurs within a database transaction. For example, a producer record is not present in the database until the producer commits the current transaction. For consumers, their offset is not recorded until the consumer commits the current transaction.

Using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka), producers and consumers can directly manage transaction-level details, including commit and abort.