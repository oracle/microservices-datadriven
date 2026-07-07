+++
archetype = "page"
title = "Advanced Features"
weight = 4
+++

This section explains advanced features of Transactional Event Queues, including message propagation between queues and the database, and error handling.

* [Message Propagation](#message-propagation)
    * [Queue to Queue Message Propagation](#queue-to-queue-message-propagation)
    * [Stopping Queue Propagation](#stopping-queue-propagation)
    * [Using Database Links](#using-database-links)
* [Error Handling](#error-handling)

## Message Propagation

Messages can be propagated within the same database or across a [database link](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-DATABASE-LINK.html) to different queues or topics. Message propagation is useful for workflows that require processing by different consumers or for event-driven actions that need to trigger subsequent processes.

#### Queue to Queue Message Propagation

Create and start two queues. `source` will be the source queue, and `dest` will be the propagated destination queue. Note that `multiple_consumers` _must_ be `true` during queue creation to enable propagation.

```sql
begin
    dbms_aqadm.create_transactional_event_queue(
        queue_name => 'source',
        queue_payload_type => 'JSON',
        multiple_consumers => true
    );
    dbms_aqadm.create_transactional_event_queue(
        queue_name => 'dest',
        queue_payload_type => 'JSON',
        multiple_consumers => true
    );
    dbms_aqadm.start_queue(
        queue_name => 'source'
    );
    dbms_aqadm.start_queue(
        queue_name => 'dest'
    );
end;
/
```

Schedule message propagation so messages from `source` are propagated to `dest`, using [`DBMS_AQADM.SCHEDULE_PROPAGATION` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-E97FCD3F-D96B-4B01-A57F-23AC9A110A0D).
```sql
begin
    dbms_aqadm.schedule_propagation(
        queue_name => 'source',
        destination_queue => 'dest'
    );
end;
/
```

Let's enqueue a message into `source`. We expect this message to be propagated to `dest`:

```sql
declare
    enqueue_options dbms_aq.enqueue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    body varchar2(200) := '{"content": "this message is propagated!"}';
begin
    enqueue_options := dbms_aq.enqueue_options_t();
    message_properties := dbms_aq.message_properties_t();
    select json(body) into message;
    dbms_aq.enqueue(
        queue_name => 'source',
        enqueue_options => enqueue_options,
        message_properties => message_properties,
        payload => message,
        msgid => msg_id
    );
    commit;
end;
/
```

If propagation does not occur, check the `JOB_QUEUE_PROCESSES` parameter and ensure its value is high enough. If the value is very low, you may need to update it with a larger value:
```sql
alter system set job_queue_processes=10;
```

#### Stopping Queue Propagation

You can stop propagation using the [DBMS_AQADM.UNSCHEDULE_PROPAGATION](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-4B4E25F4-E11F-4063-B1B8-7670C2537F47) procedure:

```sql
begin
    dbms_aqadm.unschedule_propagation(
        queue_name => 'source',
        destination_queue => 'dest'
    );
end;
/
```

Your can view queue subscribers and propagation schedules from the respective `DBA_QUEUE_SCHEDULES` and `DBA_QUEUE_SUBSCRIBERS` system views. These views are helpful for debugging propagation issues, including error messages and schedule status.

#### Using Database Links

To propagate messages between databases, a [database link](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-DATABASE-LINK.html) from the local database to the remote database must be created. The subscribe and propagation commands must be altered to use the database link.

```sql
begin
    dbms_aqadm.schedule_propagation(
        queue_name => 'source',
        -- replace with your database link
        destination => 'database_link',
        -- replace with your remote schema and queue name
        destination_queue => 'schema.queue_name' 
    );
end;
/
```

## Error Handling

Error handling is a critical component of message processing, ensuring malformed or otherwise unprocessable messages are handled correctly. Depending on the message payload and exception, an appropriate action should be taken to either replay, discard, or otherwise process the failed message. If a message cannot be dequeued due to errors, it may be moved to the [exception queue](./message-operations.md#message-expiry-and-exception-queues), if one exists. 

For errors on procedures like enqueue you may also use the standard SQL exception mechanisms:

```sql
declare
    dequeue_options dbms_aq.dequeue_options_t;
    message_properties dbms_aq.message_properties_t;
    msg_id raw(16);
    message json;
    message_buffer varchar2(500);
begin
    dequeue_options := dbms_aq.dequeue_options_t();
    message_properties := dbms_aq.message_properties_t();
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
        rollback;
        dbms_output.put_line('error dequeuing message: ' || sqlerrm);
end;
/
```
