+++
archetype = "page"
title = "Transactional Messaging"
weight = 4
+++

This section provides a detailed walkthrough of transactional messaging using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). You'll learn how to run, commit, and abort database transactions while using Kafka producers and consumers for transactional messaging.

### Kafka Example

The KafkaProducer and KafkaConsumer classes implemented by the [Kafka Java Client for Oracle Transactional Event Queues](https://github.com/oracle/okafka) provide functionality for transactional messaging, allowing developers to run database queries within a produce or consume transaction.

Transactional Messaging ensures atomicity between messaging processing and the database, ensuring that if a message is produced the corresponding database operation also commits or is rolled back in case of failure.

#### Transactional Produce

To configure a transactional producer, configure the `org.oracle.okafka.clients.producer.KafkaProducer` class with the `oracle.transactional.producer=true` property.

Once the producer instance is created, initialize the producer for transactional management using the `producer.initTransactions()` method.

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
KafkaProducer<String, String> producer = new KafkaProducer<>(props);

// Initialize the producer for database transactions
producer.initTransactions();
```

##### Producer Methods

- To start a database transaction, use the `producer.beginTransaction()` method.
- To commit the transaction, use the `producer.commitTransaction()` method.
- To retrieve the current database connection within the transaction, use the `producer.getDBConnection()` method.
- To abort the transaction, use the `producer.abortTransaction()` method.

##### Transactional Produce Example

The following Java method takes in an input record and processes it using a transactional producer. On error, the transaction is aborted and neither the DML nor topic produce are committed to the database. Assume the `processRecord` method does some DML operation with the record, like inserting or updating a table.

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

        // 3. Use the record in database DML
        processRecord(record, conn);
    } catch (Exception e) {
        // 4. On error, abort the transaction
        System.out.println("Error processing record", e);
        producer.abortTransaction();
    }

    // 5. Once complete, commit the transaction.
    producer.commitTransaction();
    System.out.println("Processed record");
}
```

#### Transactional Consume

To configure a transactional consumer, configure the `org.oracle.okafka.clients.consumer.KafkaConsumer` class with `auto.commit=false`. Disabling auto-commit allows control of database transactions through the `commitSync()` and `commitAsync()` methods.

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
            // Rollback DML from (3)
            consumer.getDBConnection().rollback();
        }
    }
}
```