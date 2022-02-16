package com.examples.enqueueDequeueTEQ;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Random;

import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;
import javax.jms.TopicSubscriber;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Service
public class EnqueueDequeueTEQ {

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;
	
	ObjectMapper mapper = new ObjectMapper();
	Random rnd = new Random();

	String queueName = "java_TEQ";
	String subscriberName = "java_SubscriberTEQ";

	public String pubSubTEQ() throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {
		String deliveryStatus;

		PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
		       ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
		  
		       ds.setURL(url);
		       ds.setUser(username);
		      // Connection con = ds.getConnection();
//		OracleDataSource ds = new OracleDataSource();
//		ds.setURL(url);
//	/*	ds.setUser(username);*/
//		Class.forName("oracle.AQ.AQOracleDriver");

		TopicConnectionFactory tc_fact = AQjmsFactory.getTopicConnectionFactory(ds);
		TopicConnection conn = null;

		conn = tc_fact.createTopicConnection();
		conn.start();
		TopicSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

		Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
		AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
		TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,
				subscriberName);

		AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage("Sample text message");
		publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
		session.commit();

		AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);
		System.out.println("------Subscriber Message: " + subscriberMessage.getText());
		deliveryStatus = "Success";
		session.commit();

		return deliveryStatus;
	}

}
