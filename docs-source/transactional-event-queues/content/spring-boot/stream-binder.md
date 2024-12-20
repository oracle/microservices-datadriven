+++
archetype = "page"
title = "Spring Cloud Stream Binder"
weight = 3
+++

[Spring Cloud Stream](https://spring.io/projects/spring-cloud-stream) is a Java framework that is designed for building event-driven microservices backed by a scalable, fault-tolerant messaging system. The [Oracle Database Transactional Event Queues stream binder implementation](https://github.com/oracle/spring-cloud-oracle/tree/main/database/spring-cloud-stream-binder-oracle-txeventq) allows developers to leverage Oracle’s database messaging platform within the Spring Cloud Stream ecosystem.

This section covers the key features of the Spring Cloud Stream Binder for Oracle Database Transactional Event Queues and getting started examples for developers.

## Key Features of the Transactional Event Queues Stream Binder

The Spring Cloud Stream Binder for Oracle Database Transactional Event Queues provides a high-throughput, reliable messaging platform built directly into the database.

- Real-time messaging with multiple publishers, consumers, and topics — all with a simple functional interface. 
- Convergence of data: Your messaging infrastructure integrates directly with the database, eliminating the need for external brokers.
- Integration with Spring Cloud Stream provides an interface that's easy-to-use and quick to get started.

## Configuring the Transactional Event Queues Stream Binder

In this section, we'll cover how to configure the Transactional Event Queues Stream Binder for a Spring Boot project.

### Project Dependencies

To start developing with the Stream Binder, add the [spring-cloud-stream-binder-oracle-txeventq](https://central.sonatype.com/artifact/com.oracle.database.spring.cloud-stream-binder/spring-cloud-stream-binder-oracle-txeventq) dependency to your Maven project:

```xml
<dependency>
    <groupId>com.oracle.database.spring.cloud-stream-binder</groupId>
    <artifactId>spring-cloud-stream-binder-oracle-txeventq</artifactId>
    <version>${txeventq-stream-binder.version}</version>
</dependency>
```

For Gradle users, add the following dependency to your project:

```groovy
implementation "com.oracle.database.spring.cloud-stream-binder:spring-cloud-stream-binder-oracle-txeventq:${txeventqStreamBinderVersion}"
```

### Stream Binder Permissions

The database user producing/consuming events with the Stream Binder requires the following database permissions. Modify the username and tablespace grant as appropriate for your application:

```sql
grant unlimited tablespace to testuser;
grant select_catalog_role to testuser;
grant execute on dbms_aq to testuser;
grant execute on dbms_aqadm to testuser;
grant execute on dbms_aqin to testuser;
grant execute on dbms_aqjms_internal to testuser;
grant execute on dbms_teqk to testuser;
grant execute on DBMS_RESOURCE_MANAGER to testuser;
grant select on sys.aq$_queue_shards to testuser;
grant select on user_queue_partition_assignment_table to testuser;
```

### Stream Binder Database Connection

The Stream Binder uses a standard JDBC connection to produce and consume messages. With YAML-style Spring application properties, it'll look something like this:

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
      connection-pool-name: StreamBinderSample
      connection-factory-class-name: oracle.jdbc.pool.OracleDataSource
```

## Suppliers, Functions and Consumers

Spring Cloud Stream uses Java suppliers, functions, and consumers to abstract references to the underlying messaging system (in this case, Transactional Event Queues). To illustrate how this works, we'll create a basic Supplier, Function, and Consumer with Spring Cloud Stream.

Our example workflow will use three functional interfaces:

- A Supplier that streams a phrase word-by-word
- A Function that processes each word from supplier and capitalizes it
- A Consumer that receives each capitalized word from the function and prints it to `stdout`

Once we've implemented the Java interfaces, we'll wire them together with Spring Cloud Stream.

### Supplier Implementation

The following Supplier implementation supplies a phrase word-by-word, indicating when it has processed the whole phrase.

```java
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;

public class WordSupplier implements Supplier<String> {
    private final String[] words;
    private final AtomicInteger idx = new AtomicInteger(0);
    private final AtomicBoolean done = new AtomicBoolean(false);

    public WordSupplier(String phrase) {
        this.words = phrase.split(" ");
    }

    @Override
    public String get() {
        int i = idx.getAndAccumulate(words.length, (x, y) -> {
            if (x < words.length - 1) {
                return x + 1;
            }
            done.set(true);
            return 0;
        });
        return words[i];
    }

    public boolean done() {
        return done.get();
    }
}
```

Next, let’s add Spring beans for our Supplier, a Function, and a Consumer. The `toUpperCase` Function takes a string and capitalizes it, and the `stdoutConsumer` Consumer prints each string it receives to `stdout`.
```java
import java.util.function.Consumer;
import java.util.function.Function;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StreamConfiguration {
    
    // Input phrase for the producer
    @Value("${phrase}")
    private String phrase;

    // Function, Capitalizes each input
    @Bean
    public Function<String, String> toUpperCase() {
        return String::toUpperCase;
    }

    // Consumer, Prints each input
    @Bean
    public Consumer<String> stdoutConsumer() {
        return s -> System.out.println("Consumed: " + s);
    }

    // Supplier, WordSupplier
    @Bean
    public WordSupplier wordSupplier() {
        return new WordSupplier(phrase);
    }
}
```

### Configure Beans with Spring Cloud Stream

Returning to the application properties, let’s configure the Spring Cloud Stream bindings for each bean defined previously.

In our binding configuration, the `wordSupplier` Supplier has the `toUpperCase` Function as a destination, and the `stdoutConsumer` Consumer reads from toUpperCase. The result of this acyclic configuration is that each word from the phrase is converted to uppercase and sent to stdout.

```yaml
# Input phrase for the wordSupplier
phrase: "Spring Cloud Stream simplifies event-driven microservices with powerful messaging capabilities."

spring:
  cloud:
    stream:
      bindings:
        wordSupplier-out-0:
          # wordSupplier output
          destination: toUpperCase-in-0
          group: t1
          producer:
            required-groups:
              - t1
        stdoutConsumer-in-0:
          # stdoutConsumer input
          destination: toUpperCase-out-0
          group: t1
    function:
      # defines the stream flow, toUppercase bridges
      # wordSupplier and stdoutConsumer
      definition: wordSupplier;toUpperCase;stdoutConsumer
```

If you’ve added the prior code to a Spring Boot application, you should see the following messages sent to `stdout` when it is run:

```
Consumed: SPRING
Consumed: CLOUD
Consumed: STREAM
Consumed: SIMPLIFIES
Consumed: EVENT-DRIVEN
Consumed: MICROSERVICES
Consumed: WITH
Consumed: POWERFUL
Consumed: MESSAGING
Consumed: CAPABILITIES.
```
