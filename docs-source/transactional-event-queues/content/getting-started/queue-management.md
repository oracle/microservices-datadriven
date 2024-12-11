+++
archetype = "page"
title = "Queue Management"
weight = 2
+++

This section covers the management of Transactional Event Queues, including the grants and roles required to use queues, hsteps to create, start, and stop queues across different programming languages and APIs.

* [Database Permissions for Transactional Event Queues](#database-permissions-for-transactional-event-queues)
  * [Permissions for SQL Packages](#permissions-for-sql-packages)
  * [Permissions for Users of Kafka APIs](#permissions-for-users-of-kafka-apis)
* [Creating, Starting, and Stopping Queues](#creating-starting-and-stopping-queues)
  * [DBMS_AQADM SQL Package](#dbms_aqadm-sql-package)
  * [Kafka APIs](#kafka-apis)
  * [Java with JMS](#java-with-jms)
  * [Python](#python)
  * [.NET](#net)
  * [JavaScript](#javascript)
  * [Oracle REST Data Services](#oracle-rest-data-services)



### Database Permissions for Transactional Event Queues

#### Permissions for SQL Packages

For management of queues using Transactional Event Queue APIs in SQL or other languages, the following permissions are recommended for users managing  queues:

```sql
grant resource, connect, unlimited tablespace to testuser;
grant aq_user_role to testuser;
grant execute on dbms_aq to testuser;
grant execute on dbms_aqadm to testuser;
grant execute ON dbms_aqin TO testuser;
grant execute ON dbms_aqjms TO testuser;
grant execute on dbms_teqk to testuser;
```

#### Permissions for Users of Kafka APIs

If your database user is interacting with Transactional Event Queues via Kafka APIs and the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka), the following permissions are recommended for users managing topics:

```sql
grant resource, connect, unlimited tablespace to testuser;
grant aq_user_role to testuser;
grant execute on dbms_aq to  testuser;
grant execute on dbms_aqadm to testuser;
grant select on gv_$session to testuser;
grant select on v_$session to testuser;
grant select on gv_$instance to testuser;
grant select on gv_$listener_network to testuser;
grant select on sys.dba_rsrc_plan_directives to testuser;
grant select on gv_$pdbs to testuser;
grant select on user_queue_partition_assignment_table to testuser;
exec dbms_aqadm.grant_priv_for_rm_plan('testuser');
```

### Creating, Starting, and Stopping Queues

#### DBMS_AQADM SQL Package

The [`DBMS_AQADM` SQL package](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html) provides procedures for the management of Transactional Event Queues.

A queue can be created using the [`DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-6841A667-1021-4E5C-8567-F71913AA4773). Queues must be started with the [`DBMS_AQADM.START_QUEUE` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-EED83332-40B1-4B0A-9E50-AC006A1A0615) before they can be used for enqueue and dequeue.

Below is an example of creating and starting a queue using DBMS_AQADM procedures.

```sql
begin
    -- create the Transactional Event Queue
    dbms_aqadm.create_transactional_event_queue(
        queue_name         => 'my_queue',
        -- when multiple_consumers is true, this will create a pub/sub "topic" - the default is false.
        multiple_consumers => false
    );

    -- start the Transactional Event Queue
    dbms_aqadm.start_queue(
        queue_name         => 'my_queue'
    );
end;
/
```

Use the [`DBMS_AQADM.STOP_QUEUE` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-14EADFE9-D7C3-472D-895D-861BB5570EED) to stop a queue. A queue must be stopped before it can be dropped using the [`DBMS_AQADM.DROP_QUEUE` procedure](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQADM.html#GUID-167A1A71-C8CB-48B4-B1B0-C98825BDE25F).

```sql
begin
    dbms_aqadm.stop_queue(
        queue_name => 'my_queue'
    );
    dbms_aqadm.drop_queue(
        queue_name => 'my_queue'
    );
end;
/
```

The `DBMS_AQADM.PURGE_QUEUE` procedure is used to clear messages from a queue.

```sql
begin
    dbms_aqadm.purge_queue(
        queue_name => 'my_queue'
    );
end;
/
```

To view the current queues in the user schema, query the `user_queues` table.

```sql
select * from user_queues;
```

You should see queue data similar to the following, for the queues available on your specific database schema.

| NAME             | QUEUE_TABLE      | QID  | QUEUE_TYPE     | MAX_RETRIES | RETRY_DELAY | ENQUEUE_ENABLED | DEQUEUE_ENABLED | RETENTION | USER_COMMENT | NETWORK_NAME | SHARDED | QUEUE_CATEGORY           | RECIPIENTS |
|------------------|------------------|------|---------------|-------------|-------------|-----------------|-----------------|-----------|--------------|--------------|---------|-------------------------|------------|
| JSON_QUEUE       | JSON_QUEUE       | 72604 | NORMAL_QUEUE   | 5           | 0           | YES             | YES             | 0         | null         | null         | TRUE    | Transactional Event Queue | SINGLE    |
| CUSTOM_TYPE_QUEUE| CUSTOM_TYPE_QUEUE| 72535 | NORMAL_QUEUE   | 5           | 0           | YES             | YES             | 0         | null         | null         | TRUE    | Transactional Event Queue | SINGLE    |
| MY_QUEUE         | MY_QUEUE         | 73283 | NORMAL_QUEUE   | 5           | 0           | YES             | YES             | 0         | null         | null         | TRUE    | Transactional Event Queue | SINGLE    |




#### Kafka APIs

You can use standard Kafka APIs to create a topic with the [Kafka Java Client for Oracle Database Transactional Event Queues](https://github.com/oracle/okafka). The following code configures connection properties for Oracle Database and creates a topic using the [`org.oracle.okafka.clients.admin.AdminClient` class](https://mvnrepository.com/artifact/com.oracle.database.messaging/okafka), which implements the `org.apache.kafka.clients.admin.Admin` interface.

```java
// Oracle Database Connection properties
Properties props = new Properties();
// Use your database service name
props.put("oracle.service.name", "freepdb1");
// Choose PLAINTEXT or SSL as appropriate for your database connection
props.put("security.protocol", "SSL");
// Your database server 
props.put("bootstrap.servers", "my-db-server");
// Path to directory containing ojdbc.properties
// If using Oracle Wallet, this directory must contain the unzipped wallet
props.put("oracle.net.tns_admin", "/my/path/");
NewTopic topic = new NewTopic("my_topic", 1, (short) 1);
try (Admin admin = AdminClient.create(props)) {
    admin.createTopics(Collections.singletonList(topic))
            .all()
            .get();
} catch (ExecutionException | InterruptedException e) {
    // Handle topic creation exception
}
```

#### Java with JMS

The [`oracle.jms` Java package](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajms/index.html) includes several APIs for managing queues, enqueuing, and dequeuing messages using JMS. The [Oracle Spring Boot Starter for AqJms](https://mvnrepository.com/artifact/com.oracle.database.spring/oracle-spring-boot-starter-aqjms) provides a comprehensive set of dependencies to get started using the Java JMS API with Transactional Event Queues. You may also use the following guide to get started, which implements a simple [producer consumer example using AqJms for Transcational Event Queues](https://medium.com/@anders.swanson.93/use-jms-for-asynchronous-messaging-in-spring-boot-d67f8349c7c4).

#### Python

When using Python, the [`python-oracledb` package](https://python-oracledb.readthedocs.io/en/latest/api_manual/aq.html#aq) is helpful for enqueuing and dequeuing messages. Queue creation and management should be handled by the Python Database Driver or a SQL script run by a database administrator.

#### .NET

Before you can use Transactional Event queues from .NET, you need to create and start queues using the appropriate PL/SQL procedures. The [OracleAQMessage class](https://docs.oracle.com/en/database/oracle/oracle-database/23/odpnt/aq-classes.html#ODPNT-GUID-4DBB419A-BCE1-467C-BA28-3611F3E012CA) can be used to enqueue and dequeue messages from queues.

#### JavaScript

Using the [`node-oracledb` package](https://node-oracledb.readthedocs.io/en/latest/api_manual/aq.html), an AqQueue class can be created from a connection for enqueuing and dequeuing messages. Queue creation and management should be handled by the node-oracledb Database Driver or a SQL script run by a database administrator.

#### Oracle REST Data Services

Oracle REST Data Services (ORDS) is a Java Enterprise Edition (Java EE) based data service that provides enhanced security, file caching features, and RESTful Web Services. Oracle REST Data Services also increases flexibility through support for deployment in standalone mode, as well as using servers like Oracle WebLogic Server and Apache Tomcat.

With ORDS, [REST APIs can be used to manage Transactional Event Queues](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/24.3/orrst/api-oracle-transactional-event-queues.html), including creating queues, producing and consuming messages.
