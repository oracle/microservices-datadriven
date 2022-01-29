package com.aq.teq.EnqueueDequeue;

import java.sql.SQLException;

import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicPublisher;
import javax.jms.TopicSubscriber;
import javax.naming.NamingException;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Service;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

@Service
@Configuration
public class EnqueueDequeueTEQ {

	static TopicConnection conn = null;
	static AQjmsSession session = null;
	static Topic topic = null;
	static TopicSubscriber subscriber1 =null;
	static TopicSubscriber subscriber2 =null;
	public static String teqWorkflow() throws JMSException, NamingException, SQLException {
		String status;
		publisher("A text msg, now=" +java.time.LocalDateTime.now());
		System.out.println("End TopicPublisher");
		//stop();
		
		subscriber();
		System.out.println("End TopicSubscriber");
		System.exit(0);
		stop();
return status="Success";
	}

	
	public static void dataSource() {
		OracleDataSource ds = new OracleDataSource();
		ds.setUser("ADMIN");
		ds.setPassword("Mayanktayal1234");
		ds.setURL("jdbc:oracle:thin:@aqdatabases_high?TNS_ADMIN=/Users/mayanktayal/Code/Database/Wallet_aqdatabase");

		TopicConnectionFactory tc_fact = AQjmsFactory.getTopicConnectionFactory(ds);

		conn = tc_fact.createTopicConnection();
		session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);
		topic = ((AQjmsSession) session).getTopic("ADMIN", "plsql_userTEQ1");
		
		conn.start();
		System.out.println("Datasource successfully created!!!");
	}
	
	public static void stop() throws JMSException {
		conn.stop();
		session.close();
		conn.close();
	}

	public static void publisher(String text) throws SQLException, JMSException {
		System.out.println("Begin publisherBlock");

		dataSource();
		
		TextMessage tm = session.createTextMessage(text);
		
		subscriber1 = session.createSubscriber(topic);
		subscriber2 = session.createDurableSubscriber(topic, "Nishant#1");
		
		TopicPublisher send = session.createPublisher(topic);
		send.publish(tm);
		session.commit();
		System.out.println("publisher, sent text=" + tm.getText());
		System.out.println("End publisherBlock");
  
	}
	

	public static void subscriber() throws JMSException, NamingException, SQLException {
		System.out.println("Begin subscriberBlock");
		dataSource();
	
		Message message1 = subscriber1.receive(1000);
		System.out.println("Message4 :" +message1+"Date   :" +java.time.LocalDateTime.now());
		
		Message message2 = subscriber2.receiveNoWait();
		System.out.println("Message1 :" +message1+"Date   :" +java.time.LocalDateTime.now());
		
		Message message3 = subscriber1.receive(-1);
		session.commit();
	}

}
