package com.examples.enqueueDequeueTEQ;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
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

import com.examples.config.ConfigData;
import com.examples.util.pubSubUtil;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;


@Service
public class EnqueueDequeueTEQ {
	
	@Autowired(required=true)
	private pubSubUtil pubSubUtil;
	
	@Autowired(required=true)
	private ConfigData configData;

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;

	String queueName = "java_TEQ11";
	String subscriberName = "java_SubscriberTEQ11";
	

	public Map<Integer,String> pubSubTEQ() throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {
		Map<Integer,String> response = new HashMap();

		TopicSession session = configData.topicDataSourceConnection();
		response.put(1, "Topic Connection created.");

		pubSubUtil.pubSub(session, "java_Subscriber", queueName, "Sample text message");
		response.put(2, "Topic pubSub  executed.");

		return response;
	}

}
