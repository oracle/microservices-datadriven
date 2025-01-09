+++
archetype = "page"
title = "Performance Tuning"
weight = 3
+++

Performance tuning is critical for ensuring the efficiency, reliability, and responsiveness of TxEventQ event processing. As systems scale and the volume of events increases, poor optimizations can lead to latency, bottlenecks, or even system failures. By applying the techniques described in this section, TxEventQ administrators can significantly enhance throughput, reduce latency, and improve the stability of event driven applications.


* [Partitioning/Sharding and Multiple Consumers](#partitioningsharding-and-multiple-consumers)
  * [Creating a Partitioned Kafka Topic](#creating-a-partitioned-kafka-topic)
  * [Message Cache Optimization](#message-cache-optimization)
* [Tuning System Parameters](#tuning-system-parameters)
  * [DB_BLOCK_SIZE](#db_block_size)
  * [JAVA_POOL_SIZE](#java_pool_size)
  * [OPEN_CURSORS](#open_cursors)
  * [PGA_AGGREGATE_TARGET](#pga_aggregate_target)
  * [PROCESSES](#processes)
  * [SESSIONS](#sessions)
  * [SGA_TARGET](#sga_target)
  * [STREAMS_POOL_SIZE](#streams_pool_size)


## Partitioning/Sharding and Multiple Consumers

Oracle Database automatically manages the database table partitions of a queue. As queue volume fluctuates, partitions may be dynamically created as necessary, for example, when the queue table expands due to a message backlog. Once all messages are dequeued and no longer needed, the database table partition is truncated and made available for reuse.

Queue partitions (or shards) can be configured on a queue during creation. A higher number of partitions per queue improves dequeue performance through consumer parallelization, but requires additional memory and database resources. When messages are enqueued, each message is routed to a specific partition of the queue. Messages within a partition maintain a strict, session-level ordering.

If you wish to manually set the number of partitions/shards for a queue, you may do so using the [SET_QUEUE_PARAMETER](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-E592137F-BB8E-49A2-80C2-C055358566C9) procedure. The following SQL script creates a queue, and configures it to have 5 partitions/shards and key based enqueue. Key based enqueue allows message routing to a specific shard within a queue by providing a message key at enqueue time.

```sql
begin
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'partitioned_queue',
            queue_payload_type => DBMS_AQADM.JMS_TYPE,
            multiple_consumers => true
    );

    -- Set the queue to have 5 partitions/shards
    dbms_aqadm.set_queue_parameter('partitioned_queue', 'SHARD_NUM', 5);
    -- The partition/shard for enqueued messages is determined by the message key
    dbms_aqadm.set_queue_parameter('partitioned_queue', 'KEY_BASED_ENQUEUE', 1);

    -- Start the queue
    dbms_aqadm.start_queue(
            queue_name         => 'partitioned_queue'
    );
end;
/
```

It is recommended to avoid creating global indexes on the partitioned table that backs a queue. Local indexes are generally not recommended either and may result in performance degradation.

### Creating a Partitioned Kafka Topic

The following Java code snippet creates a TxEventQ topic with 5 partitions using the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). The `my_topic` topic may have up to 5 distinct consumer threads per consumer group, increasing parallelization.

```java
Properties props = // Oracle Database connection properties
NewTopic topic = new NewTopic("my_topic", 5, (short) 1);
try (Admin admin = AdminClient.create(props)) {
    admin.createTopics(Collections.singletonList(topic))
        .all()
        .get();
} catch (ExecutionException | InterruptedException e) {
    // Handle topic creation exception
}
```

Note that you can use as many producers per topic as required, though it is recommended to ensure consumers are capable of consuming messages _at least_ as fast as they are produced to avoid creating a message backlog and decreasing message throughput. For additional resources and examples related to developing with Kafka APIs for TxEventQ, see the [Kafka chapter](../kafka/_index.md).

### Message Cache Optimization

TxEventQ includes a specialized message cache that allows administrators to balance [System Global Area (SGA)](https://docs.oracle.com/en/database/oracle/oracle-database/23/dbiad/db_sga.html) usage and queue performance. Management of TxEventQ's SGA usage benefits throughput, reduces latency, and allows greater concurrency. When paired with partitioning, message caching reduces the need for certain queries, DML operations, and indexes. The cache is most effective when consumers can keep up with producers, and when it is large enough to store the messages (including payloads) for all consumers and producers for using TxEventQ.

The message cache uses the Oracle Database Streams pool. You can fine-tune the memory allocation for the Streams pool using the DBMS_AQADM [SET_MIN_STREAMS_POOL](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-773FA544-1450-4A9E-BAA7-08ACF059D3EB) and [SET_MAX_STREAMS_POOL](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-9375E6C8-1BC0-4E45-8045-143927DD751C) procedures.

## Tuning System Parameters

System parameters can be modified as appropriate for your database installation and event volume to improve TxEventQ performance. This section describes key parameters for optimizing TxEventQ and provides a refresher on working with system parameters.

To update a system parameter, use the `ALTER SYSTEM` command. The following statement sets the SGA_TARGET parameter to 2 GB on the running instance and the parameter file.

```sql
alter system set sga_target = 2G scope = both;
```

The scope of a parameter may be MEMORY, SPFILE, or BOTH:
- MEMORY: changes are applied to the running instance without updating the parameter file.
- SPFILE: changes are applied to the parameter file and are available on the next restart.
- BOTH: changes are applied dynamically to the running instance, updating both memory and the parameter file.

The following query retrieves the current value of the SGA_TARGET parameter:

```sql
select name, value, isdefault, issys_modifiable, ismodified
from   v$parameter
where  name = 'sga_target';
```

### [DB_BLOCK_SIZE](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DB_BLOCK_SIZE.html)

The default block size of 8k is recommended. The block size of a database cannot be changed after database creation.

### [JAVA_POOL_SIZE](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/JAVA_POOL_SIZE.html)

The JAVA_POOL_SIZE parameter specifies the size (in bytes) of the Java pool, used by the Java memory manager for Java-related operations like method and class definitions, and Java objects during execution. If the SGA_TARGET is not set, it defaults to 24 MB. JAVA_POOL_SIZE is modifiable via ALTER SYSTEM, and its range depends on the operating system.

### [OPEN_CURSORS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/OPEN_CURSORS.html)

The OPEN_CURSORS parameter defines the maximum number of open cursors a session can have in Oracle. The default value is 50, and it can be adjusted between 0 and 65535. If you are running a large amount of producers and consumers, it’s essential to set this value high enough to avoid running out of cursors. You can modify OPEN_CURSORS using the ALTER SYSTEM command.

### [PGA_AGGREGATE_TARGET](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/PGA_AGGREGATE_TARGET.html)

The PGA_AGGREGATE_TARGET parameter specifies the target total memory available for the Program Global Area (PGA), which is used by server processes for tasks like sorting and joining. The default is 10 MB or 20% of the SGA size, whichever is greater. It is modifiable and helps optimize SQL operations by adjusting memory for working areas. When set to 0, it changes memory management to manual.

To set a hard limit for aggregate PGA memory, use the PGA_AGGREGATE_LIMIT parameter.

### [PROCESSES](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/PROCESSES.html)

The PROCESSES parameter specifies the maximum number of operating system user processes that can simultaneously connect to the database. It is essential for managing background processes, such as locks, job queues, and parallel execution. Workloads with a large number of producers and consumers may require adjustments to this parameter. Adjusting this value may require reevaluating related parameters like SESSIONS and TRANSACTIONS.

### [SESSIONS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/SESSIONS.html)

The SESSIONS parameter defines the maximum number of sessions that can be created in an Oracle database. It is calculated as (1.5 * PROCESSES) + 22 by default and can be modified within a range of 1 to 65,536. It impacts the number of concurrent users and background processes. For Pluggable Databases (PDBs), the SESSIONS parameter is adjustable but cannot exceed the root container's value. You should adjust the number based on your expected connections and background processes, including queue workloads.

### [SGA_TARGET](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/SGA_TARGET.html)

The SGA_TARGET parameter specifies the total size of the Shared Global Area (SGA) in Oracle, allowing automatic memory management of its components like the buffer cache, shared pool, and others. Its value can range from 64 MB to SGA_MAX_SIZE. It is modifiable via ALTER SYSTEM. If set to zero, SGA autotuning is disabled. Systems that make heavy using of message queueing should configure SGA_TARGET to an appropriately large value to get the most out of queue [message caching](#message-cache).

If SGA_TARGET is specified, then the following memory pools are automatically sized:
- Buffer cache (DB_CACHE_SIZE)
- Shared pool (SHARED_POOL_SIZE)
- Large pool (LARGE_POOL_SIZE)
- Java pool (JAVA_POOL_SIZE)
- Streams pool (STREAMS_POOL_SIZE)
- Data transfer cache (DATA_TRANSFER_CACHE_SIZE)

### [STREAMS_POOL_SIZE](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/STREAMS_POOL_SIZE.html)

The STREAMS_POOL_SIZE parameter defines the size of the Streams pool, a shared memory area used for TxEventQ and other database features. If SGA_TARGET and STREAMS_POOL_SIZE are both nonzero, Oracle Database Automatic Shared Memory Management uses this value as a minimum for the Streams pool. 

If both the STREAMS_POOL_SIZE and the SGA_TARGET parameters are set to 0, then the first request for Streams pool memory will transfer 10% of the buffer cache shared pool is transferred to the Streams pool.
