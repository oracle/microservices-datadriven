package com.examples.enqueueDequeueTEQ;

	import java.sql.SQLException;
	import java.util.Random;

	import javax.jms.JMSException;
	import javax.jms.Session;
	import javax.jms.Topic;
	import javax.jms.TopicConnection;
	import javax.jms.TopicConnectionFactory;
	import javax.jms.TopicSession;
	import javax.jms.TopicSubscriber;

	import org.springframework.beans.factory.annotation.Autowired;
	import org.springframework.beans.factory.annotation.Value;
	import org.springframework.stereotype.Service;

import com.examples.dao.UserDetails;
import com.examples.dao.WorkflowRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
	import com.fasterxml.jackson.databind.JsonMappingException;
	import com.fasterxml.jackson.databind.ObjectMapper;

	import oracle.AQ.AQException;

	import oracle.jdbc.pool.OracleDataSource;
	import oracle.jms.AQjmsAgent;
	import oracle.jms.AQjmsFactory;
	import oracle.jms.AQjmsSession;
	import oracle.jms.AQjmsTextMessage;
	import oracle.jms.AQjmsTopicPublisher;

	@Service
	public class EnqueueDequeueTEQ {

		@Autowired
		private WorkflowRepository workflowRepository;

		@Value("${spring.datasource.username}")
		private String username;

		@Value("${spring.datasource.password}")
		private String password;

		@Value("${spring.datasource.url}")
		private String jdbcURL;

		ObjectMapper mapper = new ObjectMapper();
		Random rnd = new Random();

		String queueName = "java_TEQ";
		String subscriberName = "java_SubscriberTEQ";


		public String pubSubTEQ()
				throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {
			String deliveryStatus;

			OracleDataSource ds = new OracleDataSource();

			ds.setUser(username);
			ds.setPassword(password);
			ds.setURL(jdbcURL);
			Class.forName("oracle.AQ.AQOracleDriver");

			TopicConnectionFactory tc_fact = AQjmsFactory.getTopicConnectionFactory(ds);
			TopicConnection conn = null;

			conn = tc_fact.createTopicConnection();
			conn.start();
			TopicSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);
			
			Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
			AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
			TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,subscriberName);

			AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage("Sample text message");
			publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
	        session.commit();

			AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);				
			System.out.println("------Subscriber Message: "+subscriberMessage.getText());
			deliveryStatus = "Success";
	        session.commit();

			return deliveryStatus;
		}

	}

