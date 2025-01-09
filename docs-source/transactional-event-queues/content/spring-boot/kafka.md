+++
archetype = "page"
title = "Kafka Starter"
weight = 2
+++

This section provides information on getting started with the Kafka Java Client for Oracle Database Transactional Event Queues in a Spring Boot application.

You can learn more about the Kafka APIs of Oracle Database Transactional Event Queues in the [Kafka chapter](../kafka/_index.md).

## Project Dependencies

[The Kafka Java Client for Oracle Database Transactional Event Queues Spring Boot Starter](https://central.sonatype.com/artifact/com.oracle.database.spring/oracle-spring-boot-starter-okafka) pulls in all necessary dependencies for developers to work with Transactional Event Queues' Kafka Java API using Spring Boot.

If you're using Maven, add the following dependency to your project:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-okafka</artifactId>
    <version>${oracle-database-starters.version}</version>
</dependency>
```

Or, if you're using Gradle:

```groovy
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-okafka:${oracleDatabaseStartersVersion}'
```

## Configuring the Starter

We'll create a simple Spring Configuration class that pulls in properties for configuring the Kafka Java Client for Oracle Database Transactional Event Queues. You can read more about these configuration properties in the [Developing With Kafka APIs](../kafka/developing-with-kafka.md) section.

```java
@Configuration
public class OKafkaConfiguration {
    public static final String TOPIC_NAME = "OKAFKA_SAMPLE";

    @Value("${ojdbc.path}")
    private String ojdbcPath;

    @Value("${bootstrap.servers}")
    private String bootstrapServers;

    // We use the default 23ai Free service name
    @Value("${service.name:freepdb1}")
    private String serviceName;

    // Use plaintext for containerized, local, or insecure databases.
    // Use of SSL with Oracle Wallet is otherwise recommend, such as for Autonomous Database.
    @Value("${security.protocol:PLAINTEXT}")
    private String securityProtocol;

    @Bean
    @Qualifier("okafkaProperties")
    public Properties kafkaProperties() {
        return OKafkaUtil.getConnectionProperties(ojdbcPath,
                bootstrapServers,
                securityProtocol,
                serviceName);
    }
}
```

### Configuring a Producer Bean

We can now configure a sample producer bean using the `org.oracle.okafka.clients.producer.KafkaProducer` class:

```java
@Bean
@Qualifier("sampleProducer")
public Producer<String, String> sampleProducer() throws IOException {
    // Create the OKafka Producer.
    Properties props = kafkaProperties();
    props.put("enable.idempotence", "true");
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
    // Note the use of the org.oracle.okafka.clients.producer.KafkaProducer class, for Oracle TxEventQ.
    return new KafkaProducer<String, String>(props);
}
```

The Producer bean can be autowired into Spring components to write messages to Oracle Database Transactional Event Queue topics. For a complete example of writing data to topics, see [Producing messages to Kafka Topics](../kafka/developing-with-kafka.md#producing-messages).

### Configuring a Consumer Bean

Next, we'll configure a sample consumer bean using the `org.oracle.okafka.clients.consumer.KafkaConsumer` class:

```java
@Bean
@Qualifier("sampleConsumer")
public Consumer<String, String> sampleConsumer() {
    // Create the OKafka Consumer.
    Properties props = kafkaProperties();
    props.put("group.id" , "MY_CONSUMER_GROUP");
    props.put("enable.auto.commit","false");
    props.put("max.poll.records", 2000);
    props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
    props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
    props.put("auto.offset.reset", "earliest");
    // Note the use of the org.oracle.okafka.clients.consumer.KafkaConsumer class, for Oracle TxEventQ.
    return new KafkaConsumer<>(props);
}
```

The Consumer bean can be autowired into Spring components to poll messages from Oracle Database Transactional Event Queue topics. For a complete consumer example, see [Consuming messages from Kafka topics](../kafka/developing-with-kafka.md#consuming-messages).

## Sample Application Code

The following samples provide application code using the Spring starter.

- [Oracle Spring Boot Sample for JSON Events and the Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/spring-cloud-oracle/tree/main/database/starters/oracle-spring-boot-starter-samples/oracle-spring-boot-sample-json-events)
- [Oracle Spring Boot Sample for the Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/spring-cloud-oracle/tree/main/database/starters/oracle-spring-boot-starter-samples/oracle-spring-boot-sample-okafka)
