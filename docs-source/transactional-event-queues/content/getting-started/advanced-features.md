+++
archetype = "page"
title = "Advanced Features"
weight = 4
+++

This section explains advanced features of Transactional Event Queues, including transactional messaging, message propagation between queues and the database, and error handling.


* [Transactional Messaging: Combine Messaging with Database Queries](#transactional-messaging-combine-messaging-with-database-queries)
  * [SQL Example](#sql-example)
  * [Kafka Example](#kafka-example)
    * [Transactional Produce](#transactional-produce)
      * [Producer Methods](#producer-methods)
      * [Transactional Produce Example](#transactional-produce-example)
    * [Transactional Consume](#transactional-consume)
      * [Consumer Methods](#consumer-methods)
      * [Transactional Consume Example](#transactional-consume-example)
* [Message Propagation](#message-propagation)
    * [Queue to Queue Message Propagation](#queue-to-queue-message-propagation)
    * [Removing Subscribers and Stopping Propagation](#removing-subscribers-and-stopping-propagation)
    * [Using Database Links](#using-database-links)
* [Error Handling](#error-handling)


## Transactional Messaging: Combine Messaging with Database Queries

Enqueue and dequeue operations occur within database transactions, allowing developers to combine database queries (DML) with messaging operations. This is particularly useful when the message contains data relevant to other tables or services within your schema.

### SQL Example

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
end;
/
```

> Note: The same pattern applies to the `dbms_aq.dequeue` procedure, allowing developers to perform DML operations within dequeue transactions.

### Kafka Example

The KafkaProducer and KafkaConsumer classes implemented by the [Kafka Java Client for Oracle Transactional Event Queues](https://github.com/oracle/okafka) provide functionality for transactional messaging, allowing developers to run database queries within a produce or consume transaction.

#### Transactional Produce

To configure a transactional producer, configure the org.oracle.okafka.clients.producer.KafkaProducer class with the `oracle.transactional.producer=true` property.

Once the producer instance is created, initialize database transactions with the `producer.initTransactions()` method.

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

// Enable Transactional messaging with the producer
props.put("oracle.transactional.producer", "true");
KafkaProducer<String, String> producer = new KafkaProducer<>(
    producerProps
);

// Initialize the producer for database transactions
producer.initTransactions();
```

##### Producer Methods

- To start a database transaction, use the `producer.beginTransaction()` method.
- To commit the transaction, use the `producer.commitTransaction()` method.
- To retrieve the current database connection within the transaction, use the `producer.getDBConnection()` method.
- To abort the transaction, use the `producer.abortTransaction()` method.

##### Transactional Produce Example

The following Java method takes in input record and processes it using a transactional producer. On error, the transaction is aborted and neither the DML nor topic produce are committed to the database. Assume the `processRecord` method does some DML operation with the record, like inserting or updating a table.

```java
public void produce(String record) {
    // 1. Begin the current transaction
    producer.beginTransaction();

    try {
        // 2. Create the producer record and prepare to send it to a topic
        ProducerRecord<String, String> pr = new ProducerRecord<>(
                topic,
                Integer.toString(idx),
                record
        );
        producer.send(pr);

        // 3. Use the record in a database query
        processRecord(record, conn);
    } catch (Exception e) {
        // 4. On error, abort the transaction
        System.out.println("Error processing record", e);
        producer.abortTransaction();
    }

    // 5. Once complete, commit the transaction
    producer.commitTransaction();
    System.out.println("Processed record");
}
```

#### Transactional Consume

To configure a transactional consumer, configure a org.oracle.okafka.clients.consumer.KafkaConsumer class with `auto.commit=false`. Disabling auto-commit will allow great control of database transactions through the `commitSync()` and `commitAsync()` methods.

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
// Set auto-commit to false for direct transaction management.
props.put("enable.auto.commit","false");
props.put("max.poll.records", 2000);
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
```

##### Consumer Methods

- To retrieve the current database connection within the transaction, use the `consumer.getDBConnection()` method.
- To commit the current transaction synchronously, use the `consumer.commitSync()` method.
- To commit the current transaction asynchronously, use the `consumer.commitAsync()` method.

##### Transactional Consume Example

The following Java method demonstrates how to use a KafkaConsumer for transactional messaging. Assume the `processRecord` method does some DML operation with the record, like inserting or updating a table.

```java
public void run() {
    this.consumer.subscribe(List.of("topic1"));
    while (true) {
        try {
            // 1. Poll a batch of records from the subscribed topics
            ConsumerRecords<String, String> records = consumer.poll(
                    Duration.ofMillis(100)
            );
            System.out.println("Consumed records: " + records.count());
            // 2. Get the current transaction's database connection
            Connection conn = consumer.getDBConnection();
            for (ConsumerRecord<String, String> record : records) {
                // 3. Do some DML with the record and connection
                processRecord(record, conn);
            }

            // 4. Do a blocking commit on the current batch of records. For non-blocking, use commitAsync()
            consumer.commitSync();
        } catch (Exception e) {
            // 5. Since auto-commit is disabled, transactions are not
            // committed when commitSync() is not called.
            System.out.println("Unexpected error processing records. Aborting transaction!");
        }
    }
}
```

## Message Propagation

Messages can be propagated within the same database or across a [database link](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-DATABASE-LINK.html) to different queues or topics. Message propagation is useful for workflows that require message processing d by different consumers or for event-driven actions that need to trigger subsequent processes.

#### Queue to Queue Message Propagation

Create and start two queues. q1 will be the source queue, and q2 will be the propagated queue.

```sql
begin
    dbms_aqadm.create_transactional_event_queue(
        queue_name => 'q1',
        queue_payload_type => 'JSON',
        multiple_consumers => true
    );
    dbms_aqadm.start_queue(
        queue_name => 'q1'
    );
    dbms_aqadm.create_transactional_event_queue(
        queue_name => 'q2',
        queue_payload_type => 'JSON',
        multiple_consumers => true
    );
    dbms_aqadm.start_queue(
        queue_name => 'q2'
    );
end;
/
```

Add a subscriber to q2 using the [`DBMS_AQADM.ADD_SUBSCRIBER` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-2B4498B0-7851-4520-89DD-E07FC4C5B2C7):

```sql
begin
    dbms_aqadm.add_subscriber(
        queue_name => 'q2',
        subscriber => sys.aq$_agent(
            'q2_test_subscriber', 
            null, 
            null
        )   
    );
end;
/
```

Schedule message propagation so messages from q1 are propagated to q2, using the [`DBMS_AQADM.SCHEDULE_PROPAGATION` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-E97FCD3F-D96B-4B01-A57F-23AC9A110A0D):

```sql
begin
    dbms_aqadm.schedule_propagation(
        queue_name => 'q1',
        destination_queue => 'q2',
        latency => 0, -- latency, in seconds, before propagating
        start_time => sysdate, -- begin propagation immediately
        duration => null -- propagate until stopped
    );
end;
/
```

Let's enqueue a message into q1. We expect this message to be propagated to q2:

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    body varchar2(200) := '{"content": "this message is propagated!"}';
begin
    select json(body) into message;
    dbms_aq.enqueue(
        queue_name => 'q1',
        enqueue_options => enqueue_options,
        message_properties => message_properties,
        payload => message,
        msgid => msg_id
    );
    commit;
end;
/
```

#### Removing Subscribers and Stopping Propagation

You can remove subscribers and stop propagation using the DBMS_AQADM.STOP_PROPAGATION procedures:

```sql
begin
    dbms_aqadm.unschedule_propagation(
        queue_name => 'q1',
        destination_queue => 'q2'
    );
end;
/
```

Remove the subscriber:

```sql
begin
    dbms_aqadm.remove_subscriber(
        queue_name => 'q2',
        subscriber => sys.aq$_agent(
            'q2_test_subscriber', 
            null, 
            null
        )   
    );
end;
/
```

Your can view queue subscribers and propagation schedules from the respective `DBA_QUEUE_SCHEDULES` and `DBA_QUEUE_SUBSCRIBERS` system views.

#### Using Database Links

To propagate messages between databases, a [database link](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-DATABASE-LINK.html) from the local database to the remote database must be created. The  subscribe and propagation commands must be altered to use the database link.

```sql
begin
    dbms_aqadm.schedule_propagation(
        queue_name => 'json_queue_1',
        destination => '<database link>.<schema name>' -- replace with your database link and schema name,
        destination_queue => 'json_queue_2'
    );
end;
/
```

## Error Handling

Error handling is a critical component of message processing, ensuring malformed or otherwise unprocessable messages are handled correctly. Depending on the message payload and exception, an appropriate action should be taken to either replay or store the message for inspection.

If a message cannot be dequeued due to errors, it may be moved to the [exception queue](./message-operations.md#message-expiry-and-exception-queues), if one exists. You can handle such errors by using PL/SQL exception handling mechanisms.

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
exception
    when others then
        dbms_output.put_line('error dequeuing message: ' || sqlerrm);
end;
/
```

