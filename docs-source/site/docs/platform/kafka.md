---
title: Apache Kafka
sidebar_position: 7
---
## Apache Kafka

[Apache Kafka](https://kafka.apache.org) is an open-source, distributed streaming platform designed for high-throughput, fault-tolerant, and scalable real-time data processing. It acts as a messaging system that enables applications to publish, subscribe to, store, and process streams of data (events or messages) efficiently.

### Installing Apache Kafka

Apache Kafka will be installed if the `kafka.enabled` is set to `true` in the `values.yaml` file. The default namespace for Apache Kafka is `kafka`

### Access the Kafka cluster

The address to the boot strap servers in Oracle Backend for Microservices and AI is:

`kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092`

An example Spring Boot application.yaml could look like this:

```yaml
spring:
  kafka:
    bootstrap-servers: kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092
```

### Strimzi Operator

The Kafka cluster is deployed using the [Strimzi](https://strimzi.io) operator. The cluster is using Zookeeper.
