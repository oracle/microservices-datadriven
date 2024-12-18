+++
archetype = "page"
title = "Developing With Kafka APIs"
weight = 2
+++

This section provides developer-friendly examples using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). The Kafka Java client implements Kafka client interfaces, allowing you to use familiar Kafka Java APIs with Oracle Database Transactional Event Queues. You'll learn how to authenticate to Oracle Database, create topics, produce messages, and consume messages using Java Kafka clients.


## Kafka Java Client for Oracle Database Transactional Event Queues

To get started using the client, add the [Kafka Java Client for Oracle Database Transactional Event Queues dependency](https://central.sonatype.com/artifact/com.oracle.database.messaging/okafka) to your project. If you're using Maven:

```xml
<dependency>
    <groupId>com.oracle.database.messaging</groupId>
    <artifactId>okafka</artifactId>
    <version>${okafka.version}</version>
</dependency>
```

Or, if you're using Gradle:

```groovy
implementation "com.oracle.database.messaging:okafka:${okafkaVersion}"
```

### Authenticating to Oracle Database

To authenticate to Oracle Database with the Kafka clients, configure a Java `Properties` object with Oracle Database-specific properties for service name, wallet location, and more.

The configured `Properties` objects are passed to Kafka Java Client for Oracle Database Transactional Event Queues implementations for Oracle Database authentication. We'll use these authentication samples as a base for creating Kafka Java cilents in follow up examples.

#### Configuring Plaintext Authentication

`PLAINTEXT` authentication uses a `ojdbc.properties` file to supply the database username and password to the Kafka Java client. Create a file named `ojdbc.properties` on your system, and populate it with your database username and password:

```
user = <database username>
password = <database password>
```

Next, in your Java application, create a `Properties` object and configure it with the following connection properties, as appropriate for your database:

```java
Properties props = new Properties();
// Database service name
props.put("oracle.service.name", "freepdb1");
// Connection protocol. Set to either PLAINTEXT or SSL
props.put("security.protocol", "PLAINTEXT");
// Oracle Database hostname and (port)
props.put("bootstrap.servers", "localhost:1521");
// Path to the directory containing ojdbc.properties
props.put("oracle.net.tns_admin", "<ojdbc.properties directory>");
```

#### Configuring SSL (Oracle Wallet) Authentication

For connections authenticated using Oracle Database Wallet, use `SSL` as the `security.protocol` and provide the path to your unzipped Oracle Database Wallet using the `oracle.net.tns_admin` property. Note that the database wallet must be downloaded, unzipped, and readable by your Java application:

```java
Properties props = new Properties();
// Database service name
props.put("oracle.service.name", "mypdb");
// Connection protocol. Set to either PLAINTEXT or SSL
props.put("security.protocol", "SSL");
// Oracle Database hostname and (port)
props.put("bootstrap.servers", "database_hostname");
// Path to wallet directory
props.put("oracle.net.tns_admin", "<wallet directory>");
```

### Creating Topics

The `org.oracle.okafka.clients.admin.AdminClient` class implements the Kafka Java Client Admin interface, and should be used to create topics for Oracle Database Transactional Event Queues when using Kafka APIs. 

The following Java class provides a sample implementation for topic creation. Assume the `props` parameter contains authenticating properties for Oracle Database, as defined in [Authenticating to Oracle Database](#authenticating-to-oracle-database). Note that while the number of topic partitions is configurable, the replication factor must always be set to `1`, as data replication is managed by the database server settings.

```java
import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;

// Implements org.apache.kafka.clients.admin.Admin for Transactional Event Queues
import org.oracle.okafka.clients.admin.AdminClient;

public class TopicCreator {
    public static void createTopic(Properties props, String topicName, int partitions) {
        NewTopic newTopic = new NewTopic(topicName, partitions, (short) 1);
        try (Admin admin = AdminClient.create(props)) {
            admin.createTopics(Collections.singletonList(newTopic))
                    .all()
                    .get();
        } catch (ExecutionException | InterruptedException e) {
            // Handle case where topic already exists or handle other exceptions as appropriate.
            if (e.getCause() instanceof TopicExistsException) {
                System.out.println("Topic already exists, skipping creation");
            } else {
                throw new RuntimeException(e);
            }
        }
    }
}
```

### Producing Messages

Similar to standard Kafka producers, producers using the Kafka Java Client for Oracle Database Transactional Event Queues must configure key and value serializers. The following snippet adds a standard StringSerializer for both, though you can provide custom implementations as needed. You may also use standard Kafka properties like `enable.idempotence` when configuring producers for Oracle Database Transactional Event Queues.


```java
// Assume props is a configured Properties object for Oracle Database
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
// Configure additional properties as needed.
props.put("enable.idempotence", "true");
```

The following Java snippet creates a producer using the Kafka Java Client for Oracle Database Transactional Event Queues, and sends a message. The `org.oracle.okafka.clients.producer.KafkaProducer` class implements the Kafka Java Client Producer interface.

```java 
// Create the producer
Producer<String, String> producer = new KafkaProducer<>(props);
// Send a message
producer.send(new ProducerRecord<>("my_topic", "my first message!"));
```

The Kafka Java Client for Oracle Database Transactional Event Queues supports all variations of `producer.send()`, allowing full control of the destination partition, and the inclusion of message headers.

### Consuming Messages

Consumers created using the Kafka Java Client for Oracle Database Transactional Event Queues use standard Kafka properties, and must specify key and value serializers. The following Java snippet configures a `Properties` object for a consumer:

```java
// Assume props is a configured Properties object for Oracle Database
props.put("group.id", "MY_CONSUMER_GROUP");
props.put("enable.auto.commit", "false");
props.put("max.poll.records", 2000);
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("auto.offset.reset", "earliest");
```

The `org.oracle.okafka.clients.consumer.KafkaConsumer` class implements the Kafka Java Client Consumer interface, allowing you to consume and process messages with a familiar API: 

```java
// Create the consumer
Consumer<String, String> consumer = new KafkaConsumer<>(props);
// Subscribe to topics
consumer.subscribe(List.of("my_topic"));
// Poll for records. Typically done in a loop
ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(500));
```

#### Transactional Messaging

The Kafka Java Client for Oracle Database Transactional Event Queues provides full support for transactional messaging capabilities, supporting database commit, rollback, and query capabilities. See the [Transactional Messaging](./transactional-messaging.md) section for comprehensive code examples.

### Custom Serializers

Kafka clients handle complex message payloads using custom serializers to convert objects to and from binary message data, allowing automatic binary-object conversions. We'll implement a serializer and deserializer for Oracle Database's native binary JSON format, [OSON](https://docs.oracle.com/en/database/oracle/oracle-database/23/adjsn/overview-json-oracle-database.html#GUID-D7BCE045-EF6D-47E9-9BB2-30C01933248E), as an example. Producers and consumers configured with the OSON serializer/deserializer will be able to read and write OSON data using Java objects.

To add necessary Oracle JSON dependencies to your project, use the Oracle JSON Collections Starter Maven package:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-json-collections</artifactId>
    <version>${oracle-starters.version}</version>
</dependency>
```

Or, if you're using Gradle:

```groovy
implementation "com.oracle.database.spring:oracle-spring-boot-starter-json-collections:${oracleStartersVersion}"
```

#### Serializer Implementation

The OSON serializer implementation uses the JSONB class from the Oracle JSON starter to convert an arbitrary Java object into OSON:

```java
package com.example;

import com.oracle.spring.json.jsonb.JSONB;
import org.apache.kafka.common.serialization.Serializer;

/**
 * The JSONBSerializer converts java objects to a JSONB byte array.
 * @param <T> serialization type.
 */
public class JSONBSerializer<T> implements Serializer<T> {
    private final JSONB jsonb;

    public JSONBSerializer(JSONB jsonb) {
        this.jsonb = jsonb;
    }

    @Override
    public byte[] serialize(String s, T obj) {
        return jsonb.toOSON(obj);
    }
}
```

The serializer can be added to a producer as a value serializer for a Java object like so:

```java
JSONB json = new JSONB(new OracleJsonFactory(), (YassonJsonb) JsonbBuilder.create());
Serializer<MyPOJO> keySerializer = new StringSerializer();
Serializer<MyPOJO> valueSerializer = new JSONBSerializer<>(jsonb);
Producer<String, MyPOJO> producer = KafkaProducer<>(props, keySerializer, valueSerializer);
```

#### Deserializer Implementation

The OSON deserializer implementation uses the JSONB class from the Oracle JSON starter to convert binary OSON data into a Java object:

```java
package com.example;

import java.nio.ByteBuffer;

import com.oracle.spring.json.jsonb.JSONB;
import org.apache.kafka.common.serialization.Deserializer;

/**
 * The JSONBDeserializer converts JSONB byte arrays to java objects.
 * @param <T> deserialization type
 */
public class JSONBDeserializer<T> implements Deserializer<T> {
    private final JSONB jsonb;
    private final Class<T> clazz;

    public JSONBDeserializer(JSONB jsonb, Class<T> clazz) {
        this.jsonb = jsonb;
        this.clazz = clazz;
    }

    @Override
    public T deserialize(String s, byte[] bytes) {
        return jsonb.fromOSON(ByteBuffer.wrap(bytes), clazz);
    }
}
```

The deserializer can be added to a consumer as a value deserializer for a Java object like so:

```java
JSONB json = new JSONB(new OracleJsonFactory(), (YassonJsonb) JsonbBuilder.create());
Deserializer<MyPOJO> keyDeserializer = new StringDeserializer();
Deserializer<MyPOJO> valueDeserializer = new JSONBDeserializer<>(jsonb, MyPOJO.class);
Consumer<String, MyPOJO> consumer = new KafkaConsumer<>(props, keyDeserializer, valueDeserializer);
```
