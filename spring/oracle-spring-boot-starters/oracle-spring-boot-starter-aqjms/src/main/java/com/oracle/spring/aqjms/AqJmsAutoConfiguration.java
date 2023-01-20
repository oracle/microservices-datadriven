package com.oracle.spring.aqjms;

/*-
 * #%L
 * Oracle Spring Boot Starter - AQ JMS
 * %%
 * Copyright (C) 2023 Oracle America, Inc.
 * %%
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 * #L%
 */

import javax.jms.ConnectionFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Configuration
@EnableConfigurationProperties(AqJmsConfigurationProperties.class)
public class AqJmsAutoConfiguration {

	@Autowired
    private AqJmsConfigurationProperties properties;

    @Bean
	@ConditionalOnMissingBean
	public PoolDataSource dataSource() {
		PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
		try {
			ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
			ds.setURL(properties.getUrl());
			ds.setUser(properties.getUsername());
			ds.setPassword(properties.getPassword());
		} catch (Exception ignore) {}
		return ds;
	}

	@Bean
	@ConditionalOnMissingBean
	public ConnectionFactory aqJmsConnectionFactory(PoolDataSource ds) {
		ConnectionFactory connectionFactory = null;
		try {
			connectionFactory = AQjmsFactory.getConnectionFactory(ds);
		} catch (Exception ignore) {}
		return connectionFactory;
	}

}
