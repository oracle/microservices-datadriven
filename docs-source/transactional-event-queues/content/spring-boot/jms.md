+++
archetype = "page"
title = "Spring JMS"
weight = 1
+++

Java Message Service (JMS) is an API that provides a standardized way for Java applications to create, send, receive, and read messages in messaging systems. [Spring JMS](https://spring.io/guides/gs/messaging-jms) uses idiomatic APIs to produce and consume messages with JMS, using the JMSTemplate class and @JMSListener annotations for producers and consumers, respectively.

In this section, we’ll implement a producer/consumer example using Spring JMS with Oracle Database Transactional Event Queues JMS APIs.

* [Project Dependencies](#project-dependencies)
* [Configure Permissions and Create a JMS Queue](#configure-permissions-and-create-a-jms-queue)
* [Connect Spring JMS to Oracle Database](#connect-spring-jms-to-oracle-database)
* [JMSTemplate Producer](#jmstemplate-producer)
* [Receive messages with @JMSListener](#receive-messages-with-jmslistener)

## Project Dependencies
To start developing with Spring JMS for Oracle Database Transactional Event Queues, add the [oracle-spring-boot-starter-aqjms](https://central.sonatype.com/artifact/com.oracle.database.spring/oracle-spring-boot-starter-aqjms) dependency to your Maven project, along with the Spring Boot JDBC starter:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jdbc</artifactId>
    <version>${spring-boot.version}</version>
</dependency>
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-aqjms</artifactId>
    <version>${oracle-database-starters.version}</version>
</dependency>
```

For Gradle users, add the following dependency to your project:

```groovy
implementation "org.springframework.boot:spring-boot-starter-data-jdbc:${springBootVersion}"
implementation "com.oracle.database.spring:oracle-spring-boot-starter-aqjms:${oracleDatabaseStartersVersion}"
```

## Configure Permissions and Create a JMS Queue

The following SQL script grants the necessary permissions to a database user for using Transactional Event Queues with JMS and creates a Transactional Event Queue with a [JMS Payload Type](../getting-started/core-concepts.md#dbms_aqadmjms_type) for the user:

```sql
grant aq_user_role to testuser;
grant execute on dbms_aq to testuser;
grant execute on dbms_aqadm to testuser;
grant execute on dbms_aqin to testuser;
grant execute on dbms_aqjms to testuser;
grant execute on dbms_teqk to testuser;

begin
    -- Create a JMS queue
    dbms_aqadm.create_transactional_event_queue(
            queue_name         => 'testuser.testqueue',
            queue_payload_type => DBMS_AQADM.JMS_TYPE,
        -- FALSE means queues can only have one consumer for each message. This is the default.
        -- TRUE means queues created in the table can have multiple consumers for each message.
            multiple_consumers => false
    );

    -- Start the queue
    dbms_aqadm.start_queue(
            queue_name         => 'testuser.testqueue'
    );
end;
/
```

## Connect Spring JMS to Oracle Database

Spring JMS with Oracle Database Transactional Event Queues uses a standard Oracle Database JDBC connection for message production and consumption. To configure this with YAML-style Spring datasource properties, it'll look something like this (`src/main/resources/application.yaml`):

```yaml
spring:
  datasource:
    username: ${USERNAME}
    password: ${PASSWORD}
    url: ${JDBC_URL}

    driver-class-name: oracle.jdbc.OracleDriver
    type: oracle.ucp.jdbc.PoolDataSourceImpl
    oracleucp:
      initial-pool-size: 1
      min-pool-size: 1
      max-pool-size: 30
      connection-pool-name: UCPSampleApplication
      connection-factory-class-name: oracle.jdbc.pool.OracleDataSource
```

Additionally, you should define a JMS ConnectionFactory bean using the AQjmsFactory class. The ConnectionFactory bean ensures Spring JMS uses Oracle Database Transactional Event Queues as the JMS provider for message operations.

```java
@Bean
public ConnectionFactory aqJmsConnectionFactory(DataSource ds) throws JMSException {
    return AQjmsFactory.getConnectionFactory(ds);
}
```

## JMSTemplate Producer

The Spring JMSTemplate bean provides an interface for JMS operations, including producing and consuming messages. The following class uses the `jmsTemplate.convertAndSend()` method to produce a message to a queue.

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

@Component
public class Producer {
    private final JmsTemplate jmsTemplate;
    private final String queueName;

    public Producer(JmsTemplate jmsTemplate,
                    @Value("${txeventq.queue.name:testqueue}") String queueName) {
        this.jmsTemplate = jmsTemplate;
        this.queueName = queueName;
    }

    public void enqueue(String message) {
        jmsTemplate.convertAndSend(queueName, message);
    }
}
```

## Receive messages with @JMSListener

The `@JMSListener` annotation may be applied to a method to configure a receiver for messages from a JMS queue. 

The following class uses the @JMSListener annotation to read messages from a queue named `testqueue`, printing each message to stdout.

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class Consumer {
    
    @JmsListener(destination = "${txeventq.queue.name:testqueue}", id = "sampleConsumer")
    public void receiveMessage(String message) {
        System.out.printf("Received message: %s%n", message);
    }
}
```
