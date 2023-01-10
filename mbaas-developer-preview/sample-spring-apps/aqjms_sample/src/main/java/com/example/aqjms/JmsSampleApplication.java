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

import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

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
  
	// @Bean
	// public PoolDataSource getDataSource() {
	// 	PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
	// 	try {
	// 		ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
	// 		ds.setURL("jdbc:oracle:thin:@//172.17.0.2:1521/pdb1");
	// 		ds.setUser("pdbadmin");
	// 		ds.setPassword("Welcome123");
	// 	} catch (Exception ignore) {}
	// 	return ds;
	// }

	// @Bean
	// public ConnectionFactory getAQjmsConnectionFactory(PoolDataSource ds) {
	// 	ConnectionFactory connectionFactory = null;
	// 	try {
	// 		connectionFactory = AQjmsFactory.getConnectionFactory(ds);
	// 	} catch (Exception ignore) {}
	// 	return connectionFactory;
	// }

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
