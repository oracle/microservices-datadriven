+++
archetype = "page"
title = "Core Concepts"
weight = 1
+++

This section provides the basic concepts of Transactional Event Queues, including the difference between queues and topics, how to create queues using SQL, and the available message payload types.

* [What are queues and topics?](#what-are-queues-and-topics)
* [Message Payload Types](#message-payload-types)
  * [DBMS_AQADM.JMS_TYPE](#dbms_aqadmjms_type)
  * [Raw](#raw)
  * [JSON](#json)
  * [Object](#object)
  * [Kafka Message Payloads](#kafka-message-payloads)

### What are queues and topics?

Queues and topics both provide high-throughput, asynchronous application communication, but have a few key differences that are relevant for developers and architects.

When using queues, messages follow a send/receive model that allows exactly one consumer. Once the message is consumed, it is discarded after a configurable interval. In contrast, topics may have multiple consumers for each message, and the message is persisted for as long as specified.

Queues work best for applications that expect to dequeue messages to a single consumer. If you plan to broadcast messages to multiple consumers, or require message replay, you should use topics. In general, topics provide greater flexibility for event-streaming applications due to the ability of consumers to independently consume or replay messages, and the database's capability of persisting the message for a specified duration.

The following SQL script uses the `DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE` procedure to create a topic by setting the `multiple_consumers` parameter to `true`. You can find the full parameter definition for the [`DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE` procedure here](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-93B0FF90-5045-4437-A9C4-B7541BEBE573).

```sql
begin
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'my_queue',
            queue_payload_type => DBMS_AQADM.JMS_TYPE,
            multiple_consumers => true
    );

    -- Start the queue
    dbms_aqadm.start_queue(
            queue_name         => 'my_queue'
    );
end;
/
```

### Message Payload Types

Transactional Event Queues support various [message payload types](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQ.html#GUID-56E78CA6-3EB0-44C9-AEB7-F13A5A077D73), allowing flexibility in how data is structured and stored within the queue. The payload type determines the format and structure of the messages that can be enqueued and dequeued. When creating a Transactional Event Queue, you may specify one of these payload types, each offering different benefits depending on your application's needs and data characteristics. Note that if not specified, `DBMS_AQADM.JMS_TYPE` is the default payload type.

Understanding these payload types is crucial for designing efficient and effective messaging solutions. The choice of payload type impacts how you interact with the queue, the kind of data you can store, and how that data is processed. Let's explore the available payload types and their use cases.

> Attempting to produce a message of the wrong payload type may result in the following error:
> 
> 
> **ORA-25207: enqueue failed, queue <schema>.<queue> is disabled from enqueueing**

#### DBMS_AQADM.JMS_TYPE

The JMS (Java Message Service) payload type is ideal for applications using JMS, as it provides a highly scalable API for asynchronous messaging.

The following script creates and starts a Transactional Event Queue using `DBMS_AQADM.JMS_TYPE` as the payload type, which is the default payload type.

```sql
-- Create a Transactional Event Queue
begin
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'my_queue',
            -- Payload can be RAW, JSON, DBMS_AQADM.JMS_TYPE, or an object type.
            -- Default is DBMS_AQADM.JMS_TYPE.
            queue_payload_type => DBMS_AQADM.JMS_TYPE,
            multiple_consumers => false
    );

    -- Start the queue
    dbms_aqadm.start_queue(
            queue_name         => 'my_queue'
    );
end;
/
```

#### Raw

When using the RAW type, the Transactional Event Queue backing table will be created with a [Large Object (LOB)](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/glossary.html#GUID-E0E22C6A-42AE-41CF-A021-5CB63BABB48E) column 32k in size for binary messages.

RAW payloads are suitable for unstructured binary data that does not fit into predefined schemas, or for simple, lightweight messages. While RAW payloads offer flexibility and efficiency, they may require additional application level processing to interpret the binary data.

The following SQL script creates a Transactional Event Queue using the RAW payload type.

```sql
begin
  dbms_aqadm.create_transactional_event_queue(
    queue_name => 'json_queue',
    queue_payload_type => 'RAW'
  );
  
  dbms_aqadm.start_queue(
    queue_name => 'json_queue'
  );
end;
/
```

#### JSON

The JSON payload type stores the JSON message data in a post-parse binary format, allowing fast access to nested JSON values. It's recommended to use the JSON payload type if you're working with document data or other unstructured JSON.

The following SQL script creates a Transactional Event Queue using the JSON payload type.

```sql
begin
  dbms_aqadm.create_transactional_event_queue(
    queue_name => 'json_queue',
    queue_payload_type => 'JSON'
  );
  
  dbms_aqadm.start_queue(
    queue_name => 'json_queue'
  );
end;
/
```

#### Object

For structured, complex messages, you may choose to set the payload type as a custom object type that was defined using `create type`. Object types must reside in the same schema as the queue/topic, and the structure of each message must exactly match the payload type.

The following SQL script defines a custom object type, and then creates a Transactional Event Queue using that type.

```sql
-- Define the payload type
create type my_message as object (
  id number,
  subject varchar2(100),
  body    varchar2(2000)
);

-- Create and start a queue using the custom payload type
begin
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'custom_type_queue',
            queue_payload_type => 'my_message'
    );

    -- Start the queue
    dbms_aqadm.start_queue(
            queue_name         => 'custom_type_queue'
    );
end;
/
```

#### Kafka Message Payloads

Topics created using the Kafka APIs for Transactional Event Queues use a Kafka message payload type, and so specifying the payload type is not necessary. Additionally, topics created using Kafka APIs should also be managed, produced and consumed from using the appropriate Kafka APIs.
