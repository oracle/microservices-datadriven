package com.cloudbank.springboot.configs;

import oracle.jdbc.pool.OracleDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import javax.sql.DataSource;
import java.sql.SQLException;

@Configuration
public class OracleDatabaseAQConfiguration {
    Logger logger = LoggerFactory.getLogger(OracleDatabaseAQConfiguration.class);

    @Autowired
    private Environment environment;

    @Bean
    public DataSource dataSource()  throws SQLException {
        OracleDataSource ods = new OracleDataSource();
        ods.setUser(environment.getProperty("spring.datasource.username"));
        ods.setPassword(environment.getProperty("spring.datasource.password"));
        ods.setURL(environment.getProperty("spring.datasource.url"));
        return ods;
    }
}
