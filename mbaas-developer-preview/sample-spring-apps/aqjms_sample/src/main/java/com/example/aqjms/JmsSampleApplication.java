// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.aqjms;

import javax.jms.ConnectionFactory;

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
	  // This provides all boot's default to this factory, including the message converter
	  configurer.configure(factory, connectionFactory);
	  // You could still override some of Boot's default if necessary.
	  return factory;
	}
  
	@Bean // Serialize message content to json using TextMessage
	public MessageConverter jacksonJmsMessageConverter() {
	  MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
	  converter.setTargetType(MessageType.TEXT);
	  converter.setTypeIdPropertyName("_type");
	  return converter;
	}
  
	public static void main(String[] args) {
	  // Launch the application
	  ConfigurableApplicationContext context = SpringApplication.run(JmsSampleApplication.class, args);
  
	  JmsTemplate jmsTemplate = context.getBean(JmsTemplate.class);
  
	  // Send a message with a POJO - the template reuse the message converter
	  System.out.println("Sending an email message.");
	  jmsTemplate.convertAndSend("mailbox", new Email("info@example.com", "Hello"));
	}
  
}
