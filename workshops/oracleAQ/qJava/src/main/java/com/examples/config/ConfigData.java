package com.examples.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import oracle.AQ.AQDriverManager;
import oracle.AQ.AQException;
import oracle.AQ.AQSession;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Configuration
public class ConfigData {

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;
	
/*	@Value("${password}")
	private String password;
	*/
	public TopicSession topicDataSourceConnection() throws SQLException, JMSException {

		PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
		ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
		ds.setURL(url);
		ds.setUser(username);
		/*ds.setPassword(password);*/
		
		TopicConnectionFactory tc_fact = AQjmsFactory.getTopicConnectionFactory(ds);
		TopicConnection conn = tc_fact.createTopicConnection();
		conn.start();
		TopicSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

		return session;
	}
	
	
	public AQSession queueDataSourceConnection() throws SQLException, ClassNotFoundException, AQException {
		Connection db_conn;
		AQSession aq_sess = null;

		Class.forName("oracle.jdbc.driver.OracleDriver");
		db_conn = DriverManager.getConnection(url/*, username, password*/);
		db_conn.setAutoCommit(false);
		
		Class.forName("oracle.AQ.AQOracleDriver");
		System.out.println("JDBC Connection opened ");
		
		aq_sess = AQDriverManager.createAQSession(db_conn);
		System.out.println("Successfully created AQSession ");

		return aq_sess;
	}
	
	public Connection dbConnection() throws SQLException, ClassNotFoundException, AQException {
		Connection db_conn;

		Class.forName("oracle.jdbc.driver.OracleDriver");
		db_conn = DriverManager.getConnection(url/*, username, password*/);
		db_conn.setAutoCommit(true);
		
		return db_conn;
	}

}
