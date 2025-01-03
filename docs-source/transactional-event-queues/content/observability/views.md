+++
archetype = "page"
title = "TxEventQ Administrative Views"
weight = 1
+++

Oracle Database provides administrative views for collecting metrics on TxEventQ topics and queues. In this section, you'll learn about each view and its use by database administrators for queue performance monitoring.

## TxEventQ Views

Find the list of TxEventQ administrative views and their column definitions in the [Oracle Database TxEventQ documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/aq-messaging-gateway-views.html#GUID-B86548B9-55B7-4CCE-8B85-FE902B948BE5). Views may be joined and grouped across queries to compose custom metrics and insights about queues and subscribers.

### [V$EQ_CACHED_PARTITIONS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_CACHED_PARTITIONS.html#REFRN-GUID-8C196A4E-BDE7-4E9F-81F7-CADAE601ED14)

Provides information about cached event stream partitions. Queries may group on identifiers like `QUEUE` id or `EVENT_STREAM_ID`.

### [V$EQ_CROSS_INSTANCE_JOBS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_CROSS_INSTANCE_JOBS.html#REFRN-GUID-AF791906-80CB-49FB-9873-6330F3748972)

The `V$EQ_CROSS_INSTANCE_JOBS` view provides information about TxEventQ cross-instance jobs. This view is crucial for monitoring and managing message forwarding across different instances in a database cluster. This view is crucial for monitoring and managing message forwarding across different instances in a database cluster. The view offers comprehensive data about each job, including:

- Job ID
- Source schema and queue name
- Event stream details
- Destination instance
- Job state and performance metrics

### V$EQ_DEQUEUE_SESSIONS

The `V$EQ_DEQUEUE_SESSIONS` view provides information about active dequeue sessions for Transactional Event Queues. The view displays real-time data about sessions that are currently dequeuing messages. Queries may group on fields like `QUEUE_ID`, `SUBSCRIBER_ID`, `CLIENT_ID`, and more.

### [V$EQ_INACTIVE_PARTITIONS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_INACTIVE_PARTITIONS.html#REFRN-GUID-3E8E6F0F-6CF4-4E81-B597-8142BF7AEE83)

The `V$EQ_INACTIVE_PARTITIONS` view provides information about inactive TxEventQ event stream partitions. The view is useful for identifying inactive partitions by their `QUEUE_NAME` or `EVENT_STREAM_ID`.

### [V$EQ_MESSAGE_CACHE](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_MESSAGE_CACHE.html#REFRN-GUID-64D1D700-B4C5-4F53-BD3C-725B19DBB7CB)

The `V$EQ_MESSAGE_CACHE` view provides performance statistics for the message cache associated with queues at the event stream partition level within an instance. This view is particularly useful for monitoring and diagnosing the behavior of event stream partitions in terms of message handling and memory usage.

### [V$EQ_MESSAGE_CACHE_ADVICE](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_MESSAGE_CACHE_ADVICE.html#REFRN-GUID-787E7AB6-13E1-4AEB-A077-7EEA961FE103)

The `V$EQ_MESSAGE_CACHE_ADVICE` view provides simulation metrics to assist in sizing the message cache for queues. By analyzing various potential cache sizes, this view helps determine the optimal configuration to ensure efficient message handling and system performance.

### [V$EQ_MESSAGE_CACHE_STAT](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_MESSAGE_CACHE_STAT.html#REFRN-GUID-267C40DA-BCA3-46C4-9115-E2CD8A676D96)

The `V$EQ_MESSAGE_CACHE_STAT` view provides global statistics on memory management for queues in the Streams pool of the System Global Area (SGA). This view offers insights into the behavior and performance of event queue partitions across all TxEventQs, aiding in effective monitoring and optimization. The view shows statistics across all queues.

### [V$EQ_NONDUR_SUBSCRIBER](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_NONDUR_SUBSCRIBER.html#REFRN-GUID-6FA0C1A8-FC9A-4EB6-97DF-948664A9B552)

The `V$EQ_NONDUR_SUBSCRIBER` view provides details about non-durable subscriptions on queues. Non-durable subscribers receive messages only while actively connected; they do not retain message state after disconnection. The view is per-queue and non-durable subscriber.

### [V$EQ_NONDUR_SUBSCRIBER_LWM](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_NONDUR_SUBSCRIBER_LWM.html#REFRN-GUID-98D91CB7-5EA3-47EB-90D3-A8BF0047D3B8)

The V$EQ_NONDUR_SUBSCRIBER_LWM view provides information about the low watermarks (LWMs) of non-durable subscribers in a Transactional Event Queue (TxEventQ). The LWM represents the lowest point in an event stream partition that a non-durable subscriber has processed.

### [V$EQ_PARTITION_STATS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_PARTITION_STATS.html#REFRN-GUID-4EA74E81-4664-436E-B58A-0857DDBD81F7)

The `V$EQ_PARTITION_STATS` view provides usage statistics for queue partition caches, specifically focusing on the queue partition cache and the dequeue log partition cache. This view is instrumental in monitoring and optimizing the performance of these caches.

### [V$EQ_REMOTE_DEQUEUE_AFFINITY](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_REMOTE_DEQUEUE_AFFINITY.html#REFRN-GUID-92DAA4F3-C3E6-4FAE-85AB-DB4C538A633B)

The `V$EQ_REMOTE_DEQUEUE_AFFINITY` view provides information about subscribers who are dequeuing messages from queues on an instance different from the event stream's owner instance. In such cases, cross-instance message forwarding is employed to deliver messages to these subscribers.

This view is useful for monitoring and managing cross-instance message forwarding in a Real Application Clusters (RAC) environment, ensuring that subscribers receive messages even when dequeuing from a different instance than the event stream's owner.

### [V$EQ_SUBSCRIBER_LOAD](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_SUBSCRIBER_LOAD.html#REFRN-GUID-65D1942E-AB78-4B1A-9AA8-E76690EA50AD)

The `V$EQ_SUBSCRIBER_LOAD` view provides data on the load and latency of all subscribers to queue event streams across instances in an Oracle Real Application Clusters (RAC) environment. This view helps in monitoring subscriber performance and identifying potential bottlenecks.

### [V$EQ_SUBSCRIBER_STAT](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_SUBSCRIBER_STAT.html#REFRN-GUID-229BE296-BD6B-47C4-9164-4E850D1F9E1A)

The `V$EQ_SUBSCRIBER_STAT` view provides statistics about subscribers of queue event streams. Each row corresponds to a specific queue, event stream and subscriber combination.

This view is useful for monitoring the performance and status of subscribers, allowing administrators to identify potential bottlenecks and optimize message processing.

### [V$EQ_UNCACHED_PARTITIONS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-EQ_UNCACHED_PARTITIONS.html#REFRN-GUID-FA912E56-CD06-4882-980B-8A92465BF086)

The `V$EQ_UNCACHED_PARTITIONS` view provides information about uncached partitions of queue event streams. Each row represents a specific event stream partition that is not currently cached.
