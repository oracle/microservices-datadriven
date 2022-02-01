package com.examples.dao;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import oracle.jdbc.pool.OracleDataSource;

@Configuration
public class config {
	@Value("${spring.datasource.url}")
	private String url;
	
	@Bean
	   public DataSource dataSource() {
	       OracleDataSource dataSource = null;
	       try {
	           dataSource = new OracleDataSource();
	           dataSource.setURL(url);
	       } catch(Exception e) {
	           e.printStackTrace();
	       }
	       return dataSource;
	   }

}
