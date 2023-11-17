---
title: "Oracle Spring Boot Starter for AQ/JMS"
---

This starter provides support for Oracle Transactional Event Queues (TxEventQ) and Oracle Advanced Queuing (AQ)
as Java Message Service (JMS) providers.  It depends on the Universal Connection Pool (UCP) starter.

**Note**: By default, the data Source and JMS Connection Factory that the starter injects into
your application share the same database transaction.  This means that you can start a
transaction, read from a queue, perform an update operation, and then commit or rollback that
whole unit of work, including the message consumption.

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

To configure your application to use Oracle Transactional Event Queues or Oracle Advanced
Queuing, you must annotate you application with the `@EnableJms` annotation, and create the
two following beans:

* A `JmsListenerContainerFactory<?>` bean, which can be created as shown in the following example.  Note that
  you can override settings if you need to.  Also, note that the name of the method defines
  the name of the factory, which you will use when creating JMS listeners.
* A `MessageConverter` bean to map objects of your class representing the payload into a
  text based format (like JSON) that can be used in the actual messages.  

**Note**: Any queues or topics that you want to use must be pre-created in the database.
See [Sample Code](https://www.oracle.com/database/advanced-queuing/#rc30sample-code) for
examples.

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
in the following example:

```java
JmsTemplate jmsTemplate = context.getBean(JmsTemplate.class);
jmsTemplate.convertAndSend("mailbox", new Email(-1, "info@example.com", "Hello"));
```

To receive messages from a JMS queue or topic, create a method that takes your message class, for example `Email`,
as input.  Annotate the method with the `@JmsListener` annotation, specifying the destination, that is the name of
the queue or topic, and the container factory name that you created earlier, as shown in the following example:

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

Note that the starter uses the configuration for `spring.datasource` as the connection
details for the Oracle Database hosting the queues and topics.  If you wish to use a different
configuration, you must use a named configuration, for example `spring.datasource.txeventq` and use Java
configuration (as shown for the [UCP starter](./ucp)) and annotate the configuration with
the standard Spring `@Qualifier` annotation, specifying the correct name, for example `txevevntq`.

