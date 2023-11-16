---
title: "Oracle Spring Boot Starters"
---

Oracle provides a number of Spring Boot Starters that make it easy to use various Oracle technologies in Spring Boot projects.

The Oracle Spring Boot Starters are available in [Maven Central](https://central.sonatype.com/namespace/com.oracle.database.spring) and include
the following starters.

**Note**: The versioning of starters was originally in line with the matching Spring Boot version, but starting in Noveember, 2023, the version
numbering scheme was changed to more closely align with Oracle Database version numbering.  The 23.4.0 starter is supported for Spring Boot 3.0
and later (including 3.1, 3.2).  For Spring Boot 2.7.x users, use the matching 2.7.x version of the starter.

### Oracle Spring Boot Starter for Universal Connection Pool

This starter provides a connection (data source) to an Oracle Database using Universal Connection Pool, which provides an efficient way
to use database connections. 

To add this starter to your project, add this Maven dependency:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-ucp</artifactId>
    <version>23.4.0</version>
    <type>pom</type>
</dependency>
```

For Gradle projects, add this dependency:

```
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-ucp:23.4.0:pom'
```

An Oracle data source will be injected into your application and can be used normally. You must configure
it as shown below, and you should also add either Spring Data JDBC or Spring Data JPA to your project.

To configure the datasource, provide a `spring.datasource` object in your Spring `application.yaml`,
or equivalent, as shown in the example below.  The `oracleucp` entry is optional, and can be used
to fine tune the configuration of the connection pool if desired.  For details of available settings,
please refer to the [JavaDoc](https://docs.oracle.com/en/database/oracle/oracle-database/21/jjuar/oracle/ucp/jdbc/UCPDataSource.html).

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.OracleDialect
        format_sql: true
    show-sql: true
  datasource:
    url: jdbc:oracle:thin:@//myhost:1521/pdb1
    username: account
    password: account
    driver-class-name: oracle.jdbc.OracleDriver
    type: oracle.ucp.jdbc.PoolDataSource
    oracleucp:
      connection-factory-class-name: oracle.jdbc.pool.OracleDataSource
      connection-pool-name: AccountConnectionPool
      initial-pool-size: 15
      min-pool-size: 10
      max-pool-size: 30
```

The `spring.datasource.url` can be in the basic format (as shown above), or in TNS format if your application
uses TNS. 

Note that the connections to the database will use the `DEDICATED` server by default.  If you wish to use `SHARED`
or `POOLED` you can append that to the basic URL, or add it to the TNS names entry.  For example, to used 
database resident pooled connections, you would change the URL shown in the example above to this: 

```yaml
  datasource:
    url: jdbc:oracle:thin:@//myhost:1521/pdb1:pooled
```

If you are using TNS, add `server=pooled` to the `connect_data` as shown below:

```
mydb_tp = (description=
 (retry_count=20)
 (retry_delay=3)
 (address=(protocol=tcps)(port=1521)(host=myhost))
 (connect_data=(service_name=pdb1)(server=pooled))
 (security=(ssl_server_dn_match=yes)))
```

If you prefer to use Java configuration, the data source can be configured as shown in this example:

```java
import oracle.jdbc.pool.OracleDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.sql.SQLException;

@Configuration
public class DataSourceConfiguration {

    @Bean
    public DataSource dataSource() throws SQLException {
        OracleDataSource dataSource = new OracleDataSource();
        dataSource.setUser("account");
        dataSource.setPassword("account");
        dataSource.setURL("jdbc:oracle:thin:@//myhost:1521/pdb1");
        dataSource.setDataSourceName("AccountConnectionPool");
        return dataSource;
    }
}
```


### Oracle Spring Boot Starter for Wallet

This starter provides support for wallet-based authentication for Oracle Database connections.  It depends
on the UCP starter.

To add this starter to your project, add this Maven dependency:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-wallet</artifactId>
    <version>23.4.0</version>
    <type>pom</type>
</dependency>
```

For Gradle projects, add this dependency:

```
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-wallet:23.4.0:pom'
```

You need to provide the wallet to your application.  You can specify the location in the `spring.datasource.url`
as shown below.

```
jdbc:oracle:thin:@mydb_tp?TNS_ADMIN=/oracle/tnsadmin
```

Note that the location specified in the `sqlnet.ora` must match the actual location of the file.

If your service is deployed in Kubernetes, the wallet should be placed in a Kubernetes secret which
is mounted into the pod at the location specified by the `TNS_ADMIN` parameter in the URL.


### Oracle Spring Boot Starter for AQ/JMS

This starter provides support for Oracle Transactional Event Queues and Oracle Advanced Queues
as JMS providers.  It depends on the UCP starter.

To add this starter to your project, add this Maven dependency:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-aqjms</artifactId>
    <version>23.4.0</version>
    <type>pom</type>
</dependency>
```

For Gradle projects, add this dependency:

```
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-aqjms:23.4.0:pom'
```

To configure your application to use Oracle Transacational Event Queues or Oracle Advanced
Queuing, you must annotate you application with the `@EnableJms` annotation, and create the
two following beans:

* A `JmsListenerContainerFactory<?>` bean, which can be created as shown below.  Note that
  you can override settings if you need to.  Also, note that the name of the method defines
  the name of the factory, which you will when creating JMS listeners.
* A `MessageConverter` bean to map objects of your class representing the payload into a
  text based format (like JSON) that can be used in the actual messages.  

```java
package com.example.aqjms;

import jakarta.jms.ConnectionFactory;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jms.DefaultJmsListenerContainerFactoryConfigurer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
import org.springframework.jms.config.JmsListenerContainerFactory;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageConverter;
import org.springframework.jms.support.converter.MessageType;

@SpringBootApplication
@EnableJms
public class JmsSampleApplication {

	@Bean
	public JmsListenerContainerFactory<?> myFactory(ConnectionFactory connectionFactory,
							DefaultJmsListenerContainerFactoryConfigurer configurer) {
	  DefaultJmsListenerContainerFactory factory = new DefaultJmsListenerContainerFactory();
	  // This provides all Boot's defaults to this factory, including the message converter
	  configurer.configure(factory, connectionFactory);
	  // You could override some of Boot's defaults here if necessary
	  return factory;
	}
  
	@Bean
	public MessageConverter jacksonJmsMessageConverter() {
	  MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
	  converter.setTargetType(MessageType.TEXT);
	  converter.setTypeIdPropertyName("_type");
	  return converter;
	}
  
	public static void main(String[] args) {
	  ConfigurableApplicationContext context = SpringApplication.run(JmsSampleApplication.class, args);
	}
  
}
```

To send a message to a JMS queue or topic, get an instance of the `JmsTemplate` from the Spring
Application context, and call the `convertAndSend()` method specifying the name of the queue or
topic, and providing the object to be converted and sent in the payload of the message, as shown
in the example below:

```java
JmsTemplate jmsTemplate = context.getBean(JmsTemplate.class);
jmsTemplate.convertAndSend("mailbox", new Email(-1, "info@example.com", "Hello"));
```

To receive messages from a JMS queue or topic, create a method that takes your message class, e.g., `Email`,
as input.  Annotate the method with the `@JmsListener` annotation, specifying the destination, i.e., the name of
the queue or topic, and the container factory name that you created earlier, as shown in the example below:

```java
package com.example.aqjms;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class Receiver {

    @JmsListener(destination = "mailbox", containerFactory = "myFactory")
    public void receiveMessage(Email email) {
      System.out.println("Received <" + email + ">");
    }

}
```

Note that the starter will use the configuration for `spring.datasource` as the connection
details for the Oracle Database hosting the queues and topics.  If you wish to use a different
one, you must use a named configuration, e.g., `spring.datasource.txeventq` and use Java
configuration (as shown above for the UCP starter) and annotate the configuration with
the standard Spring `@Qualifier` annotation, specifying the correct name, e.g., `txevevntq`.