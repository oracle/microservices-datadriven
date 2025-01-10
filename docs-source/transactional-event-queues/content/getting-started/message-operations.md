+++
archetype = "page"
title = "Message Operations"
weight = 3
+++

This section explains message operations using queues, topics, and different programming interfaces (SQL, Java, Spring JMS, and more). You’ll learn how to enqueue, dequeue, and manage messages effectively.


* [Enqueue and Dequeue, or Produce and Consume](#enqueue-and-dequeue-or-produce-and-consume)
  * [Queues](#queues)
  * [Topics](#topics)
* [Enqueuing and Dequeuing with SQL](#enqueuing-and-dequeuing-with-sql)
  * [Kafka Producers and Consumers](#kafka-producers-and-consumers)
    * [Kafka Producer](#kafka-producer)
    * [Kafka Consumer](#kafka-consumer)
  * [Enqueuing and Dequeuing with JMS](#enqueuing-and-dequeuing-with-jms)
    * [JMS APIs](#jms-apis)
    * [Message Operations in Other Languages and APIs](#message-operations-in-other-languages-and-apis)
* [Message Expiry and Exception Queues](#message-expiry-and-exception-queues)
* [Message Delay](#message-delay)
* [Message Priority](#message-priority)
* [Transactional Messaging: Combine Messaging with Database Queries](#transactional-messaging-combine-messaging-with-database-queries)

### Enqueue and Dequeue, or Produce and Consume

#### Queues

When working with queues, the preferred terms for adding and retrieving messages from Transactional Event Queues are **enqueue** and **dequeue**. 

#### Topics

When using topics, the preferred terms are **produce** and **consume**. A service that writes data to a topic is called a **producer**, and a service that reads data from a topic is called a **consumer**.

### Enqueuing and Dequeuing with SQL

> To write data to a queue, the queue must be both created and started. See [Queue Management](./queue-management.md#creating-starting-and-stopping-queues) for creating and starting queues.

The following SQL script enqueues a message for a queue with the JSON payload type:

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    body varchar2(200) := '{"content": "my first message"}';
begin
    select json(body) into message;
    dbms_aq.enqueue(
        queue_name => 'json_queue',
        enqueue_options => enqueue_options,
        message_properties => message_properties,
        payload => message,
        msgid => msg_id
    );
end;
/
```

Next, we'll dequeue the message and print it to the console:

```sql
declare
    dequeue_options dbms_aq.dequeue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    message_buffer varchar2(500);
begin
    dequeue_options.navigation := dbms_aq.first_message;
    dequeue_options.wait := dbms_aq.no_wait;
    
    dbms_aq.dequeue(
        queue_name => 'json_queue',
        dequeue_options => dequeue_options,
        message_properties => message_properties,
        payload => message,
        msgid => msg_id
    );
    select json_value(message, '$.content') into message_buffer;
    dbms_output.put_line('message: ' || message_buffer);
end;
/
```

You may also query a message's content by ID from the underlying queue table:

```sql
select q.user_data from json_queue q
where msgid = '<msg id>'; -- Query using the message ID

-- {"content":"my first message"}
```

#### Kafka Producers and Consumers

> To produce or consume topic data, the topic must be created. See [Queue Management](./queue-management.md#kafka-apis) for a topic creation example.

##### Kafka Producer

The following Java snippet creates an org.oracle.okafka.clients.producer.KafkaProducer instance capable of producing data to Transactional Event Queue topics. Note the use of Oracle Database connection properties, and Kafka producer-specific properties like `enable.idempotence` and `key.serializer`.

The org.oracle.okafka.clients.producer.KafkaProducer class implements the org.apache.kafka.clients.producer.Producer interface, allowing it to be used in place of a Kafka Java client producer.

```java
Properties props = new Properties();
// Use your database service name
props.put("oracle.service.name", "freepdb1");
// Choose PLAINTEXT or SSL as appropriate for your database connection
props.put("security.protocol", "SSL");
// Your database server 
props.put("bootstrap.servers", "my-db-server");
// Path to directory containing ojdbc.properties
// If using Oracle Wallet, this directory must contain the unzipped wallet (such as in sqlnet.ora)
props.put("oracle.net.tns_admin", "/my/path/");

props.put("enable.idempotence", "true");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
Producer<String, String> okafkaProducer = new KafkaProducer<>(props);
```

The following Java class produces a stream of messages to a topic, using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). Note that the implementation does not use any Oracle-specific classes, only Kafka interfaces. This allows developers to drop in an org.oracle.okafka.clients.producer.KafkaProducer instance without code changes.

```java
import java.util.stream.Stream;

import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class SampleProducer<T> implements Runnable, AutoCloseable {
    private final Producer<String, T> producer;
    private final String topic;
    private final Stream<T> inputs;

    public SampleProducer(Producer<String, T> producer, String topic, Stream<T> inputs) {
        this.producer = producer;
        this.topic = topic;
        this.inputs = inputs;
    }

    @Override
    public void run() {
        inputs.forEach(t -> {
            System.out.println("Produced record: " + t);
            producer.send(new ProducerRecord<>(topic, t));
        });
    }

    @Override
    public void close() throws Exception {
        if (this.producer != null) {
            producer.close();
        }
    }
}
```

##### Kafka Consumer

The following Java snippet creates an org.oracle.okafka.clients.consumer.KafkaConsumer instance capable of records from Transactional Event Queue topics. Note the use of Oracle Database connection properties, and Kafka consumer-specific properties like `group.id` and `max.poll.records`.

The org.oracle.okafka.clients.consumer.KafkaConsumer class implements the org.apache.kafka.clients.consumer.Consumer interface, allowing it to be used in place of a Kafka Java client consumer.

```java
Properties props = new Properties();
// Use your database service name
props.put("oracle.service.name", "freepdb1");
// Choose PLAINTEXT or SSL as appropriate for your database connection
props.put("security.protocol", "SSL");
// Your database server 
props.put("bootstrap.servers", "my-db-server");
// Path to directory containing ojdbc.properties
// If using Oracle Wallet, this directory must contain the unzipped wallet (such as in sqlnet.ora)
props.put("oracle.net.tns_admin", "/my/path/");

props.put("group.id" , "MY_CONSUMER_GROUP");
props.put("enable.auto.commit","false");
props.put("max.poll.records", 2000);
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
Consumer<String, String> okafkaConsumer = new KafkaConsumer<>(props);
```

The following Java class consumes messages from a topic, using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). Like the producer example, the consumer only does not use any Oracle classes, only Kafka interfaces.


```java
import java.time.Duration;
import java.util.List;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecords;

public class SampleConsumer<T> implements Runnable, AutoCloseable {
    private final Consumer<String, T> consumer;
    private final String topic;

    public SampleConsumer(Consumer<String, T> consumer, String topic) {
        this.consumer = consumer;
        this.topic = topic;
    }

    @Override
    public void run() {
        consumer.subscribe(List.of(topic));
        while (true) {
            ConsumerRecords<String, T> records = consumer.poll(Duration.ofMillis(100));
            System.out.println("Consumed records: " + records.count());
            processRecords(records);
            // Commit records when done processing.
            consumer.commitAsync();
        }
    }

    private void processRecords(ConsumerRecords<String, T> records) {
        // Application implementation of record processing.
    }

    @Override
    public void close() throws Exception {
        if (consumer != null) {
            consumer.close();
        }
    }
}
```

#### Enqueuing and Dequeuing with JMS

JMS (Java Message Service) provides a standard way to enqueue and dequeue messages. This section shows how to use plain Java JMS APIs and Spring JMS integration using the [`oracle.jms` Java package](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajms/index.html) and the [Oracle Spring Boot Starter for AqJms](https://mvnrepository.com/artifact/com.oracle.database.spring/oracle-spring-boot-starter-aqjms).

##### JMS APIs

The AQJmsFactory class is used to create a JMS ConnectionFactory, from a Java DataSource or connection parameters. Once configured, the JMS ConnectionFactory instance can be used with standard JMS APIs to produce and consume messages. 

The following Java snippet uses a JMS ConnectionFactory to produce a text message.

```java
DataSource ds = // Configure the Oracle Database DataSource according to your database connection information
ConnectionFactory cf = AQjmsFactory.getConnectionFactory(ds);
try (Connection conn = cf.createConnection()) {
    Session session = conn.createSession();
    Queue myQueue = session.createQueue("my_queue");
    MessageProducer producer = session.createProducer(myQueue);
    producer.send(session.createTextMessage("Hello World"));
}
```
The following Java snippet uses a JMS ConnectionFactory to consume a text message.

```java
DataSource ds = // Configure the Oracle Database DataSource according to your database connection information
ConnectionFactory cf = AQjmsFactory.getConnectionFactory(ds);
try (Connection conn = cf.createConnection()) {
    Session session = conn.createSession();
    Queue myQueue = session.createQueue("my_queue");
    MessageConsumer consumer = session.createConsumer(myQueue);
    conn.start();
    Message msg = consumer.receive(10000); // Wait for 10 seconds
    if (msg != null && msg instanceof TextMessage) {
        TextMessage textMsg = (TextMessage) msg;
        System.out.println("Received message: " + textMsg.getText());
    }
}
```

##### Message Operations in Other Languages and APIs

For Python, Javascript, .NET, and ORDS, refer to the respective documentation for code samples:

- [Python](https://python-oracledb.readthedocs.io/en/latest/api_manual/aq.html#aq)
- [JavaScript](https://node-oracledb.readthedocs.io/en/latest/api_manual/aq.html)
- [.NET](https://docs.oracle.com/en/database/oracle/oracle-database/23/odpnt/aq-classes.html#ODPNT-GUID-4DBB419A-BCE1-467C-BA28-3611F3E012C)
- [ORDS REST APIs](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.3/orrst/api-oracle-transactional-event-queues.html)

### Message Expiry and Exception Queues

When enqueuing a message, you can specify an expiration time using the `expiration` attribute of the message_properties object. This sets the number of seconds during which the message is available for dequeuing.
Messages that exceed their expiration time are automatically moved to an exception queue for further processing or inspection (including queries or dequeue operations). The exception queue contains any expired or failed messages, and uses the same underlying table as the main queue.

The following SQL script creates a queue for JMS payloads, and an associated [exception queue](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-D18BF6B8-01F2-4E39-BD05-41E3B5A97C07) for failed or expired messages.

```sql
begin
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'my_queue',
            multiple_consumers => false
    );
    dbms_aqadm.start_queue(
            queue_name         => 'my_queue'
    );
    dbms_aqadm.create_eq_exception_queue(
        queue_name => 'my_queue',
        exception_queue_name => 'my_queue_eq'
    );
end;
```

The following SQL script enqueues a JMS payload, configuring the expiry time so that after 60 seconds, the message is moved to the exception queue.

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    message_handle raw(16);
    message sys.aq$_jms_text_message;
begin
    message := sys.aq$_jms_text_message.construct();
    message.set_text('this is my message');

    message_properties.expiration := 60; -- message expires in 60 seconds
    dbms_aq.enqueue(
        queue_name => 'my_queue',
        enqueue_options => enqueue_options,
        message_properties => message_properties,
        payload => message,
        msgid => message_handle
    );
    commit;
end;
/
```

### Message Delay

When enqueuing a message, you can specify a delay (in seconds) before the message becomes available for dequeuing. Message delay allows you to schedule messages to be available for consumers after a specified time, and is configured using the `delay` attribute of the message_properties object. 

When enqueuing delayed messages, the `DELIVERY_TIME` column will be configured with the date the message is available for consumers.

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    message_handle raw(16);
    message sys.aq$_jms_text_message;
begin
    message := sys.aq$_jms_text_message.construct();
    message.set_text('this is my message');

    message_properties.delay := 7*24*60*60; -- Delay for 7 days
    dbms_aq.enqueue(
            queue_name => 'my_queue',
            enqueue_options => enqueue_options,
            message_properties => message_properties,
            payload => message,
            msgid => message_handle
    );
    commit;
end;
/
```

### Message Priority

When enqueuing a message, you can specify its priority using the priority attribute of the message_properties object. This attribute allows you to control the order in which messages are dequeued. The lower a message's priority number, the higher the message's precedence for consumers.

When enqueuing prioritized messages, the `PRIORITY` column in the queue table will be populated with the priority number.

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    message_handle raw(16);
    message sys.aq$_jms_text_message;
begin
    message := sys.aq$_jms_text_message.construct();
    message.set_text('this is my message');

    message_properties.priority := 1; -- A lower number indicates higher priority
    dbms_aq.enqueue(
            queue_name => 'my_queue',
            enqueue_options => enqueue_options,
            message_properties => message_properties,
            payload => message,
            msgid => message_handle
    );
    commit;
end;
/
```

### Transactional Messaging: Combine Messaging with Database Queries

Enqueue and dequeue operations occur within database transactions, allowing developers to combine database DML with messaging operations. This is particularly useful when the message contains data relevant to other tables or services within your schema.

In the following example, a DML operation (an `INSERT` query) is combined with an enqueue operation in the same transaction. If the enqueue operation fails, the `INSERT` is rolled back. The orders table serves as the example.

```sql
create table orders (
    id number generated always as identity primary key,
    product_id number not null,
    quantity number not null,
    order_date date default sysdate
);

declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    body varchar2(200) := '{"product_id": 1, "quantity": 5}';
    product_id number;
    quantity number;
begin
    -- Convert the JSON string to a JSON object
    message := json(body);

    -- Extract product_id and quantity from the JSON object
    product_id := json_value(message, '$.product_id' returning number);
    quantity := json_value(message, '$.quantity' returning number);

    -- Insert data into the orders table
    insert into orders (product_id, quantity)
        values (product_id, quantity);

    -- Enqueue the message
    dbms_aq.enqueue(
            queue_name => 'json_queue',
            enqueue_options => enqueue_options,
            message_properties => message_properties,
            payload => message,
            msgid => msg_id
    );
    commit;
exception
    when others then
        -- Rollback the transaction on error
        rollback;
        dbms_output.put_line('error dequeuing message: ' || sqlerrm);
end;
/
```

> Note: The same pattern applies to the `dbms_aq.dequeue` procedure, allowing developers to perform DML operations within dequeue transactions.
