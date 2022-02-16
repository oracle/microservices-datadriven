package com.examples;

import java.sql.SQLException;
import java.util.Scanner;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import oracle.jdbc.pool.OracleDataSource;

@Configuration
@EnableAutoConfiguration
public class config {
	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;

//	@Bean
//	OracleDataSource dataSource() throws SQLException {
//		OracleDataSource dataSource = new OracleDataSource();
//		dataSource.setUser(username);
//		dataSource.setURL(url);
//		dataSource.setDriverType("thin");
//		dataSource.setImplicitCachingEnabled(true);
//		System.out.println("opened");
//
//		return dataSource;
//	}

}
