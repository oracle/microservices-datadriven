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
	
	 @Bean
	    DataSource dataSource() throws SQLException {
	        OracleDataSource dataSource = new OracleDataSource();
	        dataSource.setUser(username);
	        Scanner scanner = new Scanner(System.in);
	        System.out.print("Enter wallet password: ");
	        String password = scanner.next();
	        dataSource.setPassword(password);
	        dataSource.setURL(url);
	        dataSource.setDriverType("oracle.jdbc.OracleDriver");
	        dataSource.setImplicitCachingEnabled(true);
	        return dataSource;
	    }
}
