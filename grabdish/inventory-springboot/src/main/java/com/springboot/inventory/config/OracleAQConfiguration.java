package com.springboot.inventory.config;

import java.sql.SQLException;

import javax.jms.Destination;
import javax.jms.JMSException;
import javax.jms.QueueConnectionFactory;
import javax.jms.Session;
import javax.sql.DataSource;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.jms.DefaultJmsListenerContainerFactoryConfigurer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
import org.springframework.jms.config.JmsListenerContainerFactory;
import org.springframework.jms.support.destination.DynamicDestinationResolver;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsFactory;

@Configuration
public class OracleAQConfiguration {
	Logger logger = LoggerFactory.getLogger(OracleAQConfiguration.class);

	@Autowired
	private Environment environment;

//	@Autowired
//	private DataSource dataSource;

	@Bean
	public DataSource dataSource() throws SQLException {

//		PoolDataSource atpInventoryPDB = PoolDataSourceFactory.getPoolDataSource();
//		atpInventoryPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
//		atpInventoryPDB.setURL(environment.getProperty("db_url"));
//		atpInventoryPDB.setUser(environment.getProperty("db_user"));
//		atpInventoryPDB.setPassword(environment.getProperty("db_password"));
		OracleDataSource ds = new OracleDataSource();

		ds.setUser(environment.getProperty("db_user"));
		logger.info("USER: " + environment.getProperty("db_user"));

		ds.setPassword(environment.getProperty("db_password"));
		logger.info("Password: " + environment.getProperty("db_password"));

		ds.setURL(environment.getProperty("db_url"));
		logger.info("URL: " + environment.getProperty("db_url"));

		logger.info("OracleAQConfiguration: dataSource success" + ds);
		return ds;
	}

	@Bean
	public QueueConnectionFactory connectionFactory(DataSource dataSource) throws JMSException, SQLException {
		logger.info("OracleAQConfiguration: connectionFactory success");
		return AQjmsFactory.getQueueConnectionFactory(dataSource);
	}

	@Bean
	public JmsListenerContainerFactory<?> queueConnectionFactory(QueueConnectionFactory connectionFactory,
			DefaultJmsListenerContainerFactoryConfigurer configurer) {
		DefaultJmsListenerContainerFactory factory = new DefaultJmsListenerContainerFactory();
		configurer.configure(factory, connectionFactory);
		factory.setPubSubDomain(false);
		return factory;
	}

	@Bean
	public JmsListenerContainerFactory<?> topicConnectionFactory(QueueConnectionFactory connectionFactory,
			DefaultJmsListenerContainerFactoryConfigurer configurer) {
		DefaultJmsListenerContainerFactory factory = new DefaultJmsListenerContainerFactory();
		factory.setPubSubDomain(true);
		configurer.configure(factory, connectionFactory);
		factory.setClientId("inventory_service");
		return factory;
	}

	@Bean
	public DynamicDestinationResolver destinationResolver() {
		return new DynamicDestinationResolver() {
			@Override
			public Destination resolveDestinationName(Session session, String destinationName, boolean pubSubDomain)
					throws JMSException {
				return super.resolveDestinationName(session, destinationName, true);
			}
		};
	}
}