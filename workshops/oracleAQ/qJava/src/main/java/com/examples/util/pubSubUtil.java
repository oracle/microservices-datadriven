package com.examples.util;

import java.sql.SQLException;

import javax.jms.JMSException;
import javax.jms.Topic;
import javax.jms.TopicSession;
import javax.jms.TopicSubscriber;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.examples.dao.UserDetails;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.AQ.AQException;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsDestination;
import oracle.jms.AQjmsDestinationProperty;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;

@Component
public class pubSubUtil {

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;
	
	ObjectMapper mapper = new ObjectMapper();

	public UserDetails pubSubWorkflowTxEventQ(TopicSession session, String subscriberName, String queueName, UserDetails user)
			throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {

		Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
		
		AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
		TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,subscriberName, "JMSCorrelationID ="+ subscriberName);
		
		String jsonString = mapper.writeValueAsString(user);	
		
		System.out.println("------Publisher Message: "+jsonString);
		AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage(jsonString);
		publisherMessage.setJMSCorrelationID(subscriberName);
		publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
        session.commit();

		AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);				
		UserDetails userData = mapper.readValue(subscriberMessage.getText(), UserDetails.class);
		System.out.println("------Subscriber Message: "+subscriberMessage.getText());
        session.commit();

		return userData;
	}
	
	public UserDetails pubSubWorkflowAQ(TopicSession session, String subscriberName, String queueName, UserDetails user)
			throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {

		Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
		AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
		TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,subscriberName);

		String jsonString = mapper.writeValueAsString(user);
		AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage(jsonString);
		publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
        session.commit();

		AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);				
		UserDetails userData = mapper.readValue(subscriberMessage.getText(), UserDetails.class);
        session.commit();

		return userData;
	}

	
	public void pubSub(TopicSession session, String subscriberName, String queueName, String message)
			throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {

		Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
		AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
		TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,subscriberName);

		AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage(message);
		System.out.println("------Publisher Message: "+publisherMessage.getText());
		publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
		session.commit();

		AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);
		System.out.println("------Subscriber Message: " + subscriberMessage.getText());
		session.commit();
	}
	
	public Topic setupTopic(TopicSession tsess, String tableName, String topicName) throws AQException, JMSException {
	      AQQueueTableProperty qtprop ;
	      AQQueueTable qtable;
	      AQjmsDestinationProperty dprop;
	      Topic topic;
	     
	         System.out.println("Creating Input Queue Table...") ;

	         /* Drop the queue if already exists */
	         try {
	           qtable=((AQjmsSession)tsess).getQueueTable(username, tableName );
	           qtable.drop(true);
	         } catch (Exception e) {} ;

	         qtprop = new AQQueueTableProperty ("SYS.AQ$_JMS_TEXT_MESSAGE") ;
	         qtprop.setMultiConsumer(true) ;
	         qtprop.setPayloadType("SYS.AQ$_JMS_TEXT_MESSAGE") ;
	         qtable = ((AQjmsSession)tsess).createQueueTable(username, tableName, qtprop) ;

	         System.out.println ("Creating Topic input_queue...");
	         dprop = new AQjmsDestinationProperty() ;
	         topic=((AQjmsSession)tsess).createTopic( qtable, topicName, dprop) ;

	         ((AQjmsDestination)topic).start(tsess, true, true);
	         System.out.println("Successfully setup Topic");
			
	         return topic;  
	   }

}
