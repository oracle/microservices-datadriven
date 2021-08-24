package com.springboot.inventory.config;

import java.sql.SQLException;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.jms.QueueConnectionFactory;
import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.core.JmsTemplate;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import org.springframework.core.env.Environment;

@Configuration
public class OracleAQConfiguration {
    Logger logger = LoggerFactory.getLogger(OracleAQConfiguration.class);
  
    @Autowired
    private Environment environment;
    
    @Bean
    public DataSource dataSource() throws SQLException {
        OracleDataSource ds = new OracleDataSource();
        
        ds.setUser(environment.getProperty("db_user"));
        logger.info("USER: "+ environment.getProperty("db_user"));
        
        ds.setPassword(environment.getProperty("db_password"));
        logger.info("Password: "+ environment.getProperty("db_password"));
        
        ds.setURL(environment.getProperty("db_url"));
        logger.info("URL: "+ environment.getProperty("db_url"));
        
        logger.info("OracleAQConfiguration-->dataSource success"+ds);
        return ds;
    }

    @Bean
    public QueueConnectionFactory connectionFactory(DataSource dataSource) throws JMSException, SQLException {
        logger.info("OracleAQConfiguration-->AQ factory success");
        return AQjmsFactory.getQueueConnectionFactory(dataSource);
    }

    @Bean
    public JmsTemplate jmsTemplate(ConnectionFactory conFactory) throws Exception{
        JmsTemplate jmsTemplate = new JmsTemplate();
        jmsTemplate.setDefaultDestinationName("inventoryqueue");
        jmsTemplate.setSessionTransacted(true);
        jmsTemplate.setConnectionFactory(conFactory);

        logger.info("Jms Configuration-->jms template success");
        return jmsTemplate;
    }
}