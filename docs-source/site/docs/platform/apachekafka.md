---
title: Apache Kafka
sidebar_position: 2
---
## Apache Kafka

[Apache Kafka](https://kafka.apache.org) is an open-source, distributed streaming platform designed for high-throughput, fault-tolerant, and scalable real-time data processing. It acts as a messaging system that enables applications to publish, subscribe to, store, and process streams of data (events or messages) efficiently.

### Installing Apache Kafka

Apache Kafka will be installed if the `kafka.enabled` is set to `true` in the `values.yaml` file. The default namespace for Apache Kafka is `kafka`.

### Strimzi Operator

The Kafka cluster in Oracle Backend for Microservices and AI is deployed and managed using the [Strimzi](https://strimzi.io) operator, a Kubernetes-native solution for running Apache Kafka on Kubernetes. [Strimzi Documentation](https://strimzi.io/docs/operators/latest/overview). Strimzi provides a set of operators that automate the deployment, configuration, and management of Apache Kafka clusters on Kubernetes.

#### Cluster Configuration

The default Kafka cluster deployed in Oracle Backend for Microservices and AI uses ZooKeeper for cluster coordination. The cluster can be accessed at:

`kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092`

### Using Kafka with Spring Boot

To connect your Spring Boot application to the Kafka cluster deployed in Oracle Backend for Microservices and AI, you need to add the following dependencies and configuration. [Spring for Apache Kafka Documentation](https://spring.io/projects/spring-kafka/)

#### Dependencies

**Maven** (`pom.xml`):

```xml
<dependencies>
    <!-- Spring Kafka -->
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
</dependencies>
```

#### Spring Boot Configuration

Create or update your `application.yaml` file to connect to the Kafka cluster:

```yaml
spring:
  kafka:
    # Bootstrap server address
    bootstrap-servers: kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092

    # Consumer configuration
    consumer:
      group-id: my-application-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer

    # Producer configuration
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
```

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
