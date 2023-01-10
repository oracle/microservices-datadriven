package com.oracle.spring.aqjms.config;

import javax.jms.ConnectionFactory;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.oracle.spring.aqjms.properties.JmsConfigurationProperties;

import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Configuration
@EnableConfigurationProperties(JmsConfigurationProperties.class)
public class JmsConfiguration {

    private JmsConfigurationProperties properties;

    public JmsConfiguration(JmsConfigurationProperties properties) {
        this.properties = properties;
    }

    @Bean
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
	public ConnectionFactory aqJmsConnectionFactory(PoolDataSource ds) {
		ConnectionFactory connectionFactory = null;
		try {
			connectionFactory = AQjmsFactory.getConnectionFactory(ds);
		} catch (Exception ignore) {}
		return connectionFactory;
	}

}