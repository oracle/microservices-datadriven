package com.examples.workflowAQ;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
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
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.examples.config.ConfigData;
import com.examples.dao.UserDetails;
import com.examples.dao.UserDetailsDao;
import com.examples.util.pubSubUtil;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.AQ.AQDriverManager;
import oracle.AQ.AQException;
import oracle.AQ.AQQueue;
import oracle.AQ.AQQueueProperty;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.AQ.AQSession;
import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Service
public class WorkflowAQ {

	@Autowired
	UserDetailsDao userDetailsDao;
	
	@Autowired(required=true)
	private ConfigData configData;

	@Autowired(required=true)
	private pubSubUtil pubSubUtil;
	
	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;

	ObjectMapper mapper = new ObjectMapper();
	Random rnd = new Random();

	String userQueueTable 				  = "java_UserQueueTable"+rnd.nextInt(9999);
	String userQueueName 				  = "java_UserQueue"+rnd.nextInt(9999);
	String userApplicationSubscriber      = "java_userAppSubscriber";
	String userDelivererSubscriber        = "java_userDelivererSubscriber";

	String delivererQueueTable            = "java_DelivererQueueTable"+rnd.nextInt(9999);
	String delivererQueueName             = "java_DelivererQueue"+rnd.nextInt(9999);
	String delivererUserSubscriber        = "java_delivererUserSubscriber";
	String delivererApplicationSubscriber = "java_delivererApplicationSubscriber";

	String applicationQueueTable          = "java_ApplicationQueueTable"+rnd.nextInt(9999);
	String applicationQueueName           = "java_ApplicationQueue"+rnd.nextInt(9999);
	String applicationUserSubscriber      = "java_appUserSubscriber";
	String applicationDelivererSubscriber = "java_appDelivererSubscriber";

	UserDetails userToApplication_message;
	UserDetails userToDeliverer_message;
	UserDetails delivererToUser_message;
	UserDetails delivererToApplication_message;
	UserDetails applicationToUser_message;
	UserDetails applicationToDeliverer_message;

	public Map<Integer,String> pubSubWorkflowAQ() throws JMSException, AQException, SQLException, ClassNotFoundException,
			JsonMappingException, JsonProcessingException {
		String deliveryStatus;
		Map<Integer,String> response = new HashMap();
		
		TopicSession session = configData.topicDataSourceConnection();
		response.put(1, "Topic Connection created.");
		
		/* Setup */
		AQSession qsession = createSession();
		createQueue(qsession, username, userQueueTable, userQueueName);
		createQueue(qsession, username, delivererQueueTable, delivererQueueName);
		createQueue(qsession, username, applicationQueueTable, applicationQueueName);
		
		/* 1: USER PLACED OREDER ON APPLICATION */
		userToApplication_message = pubSubUtil.pubSubWorkflow(session, userApplicationSubscriber, userQueueName,new UserDetails(rnd.nextInt(99999), "DBUSER", 0, "Pending", "US"));
		response.put(2,"USER ORDER MESSAGE              - ORDERID: " + userToApplication_message.getOrderId() + ", OTP: "
				+ userToApplication_message.getOtp() + ", DeliveryStatus: "
				+ userToApplication_message.getDeliveryStatus());

		/* 2: APPLICATION SHARES OTP TO USER */
		applicationToUser_message = pubSubUtil.pubSubWorkflow(session, applicationUserSubscriber, applicationQueueName,
				new UserDetails(userToApplication_message.getOrderId(), userToApplication_message.getUsername(),
						rnd.nextInt(9999), userToApplication_message.getDeliveryStatus(),
						userToApplication_message.getDeliveryLocation()));
		response.put(3,"APPLICATION TO USER MESSAGE     - ORDERID: " + applicationToUser_message.getOrderId()
				+ ", OTP: " + applicationToUser_message.getOtp() + ", DeliveryStatus: "
				+ applicationToUser_message.getDeliveryStatus());

		/* 3: APPLICATION CREATES AN USER RECORD */
		userDetailsDao.add(applicationToUser_message);
/*	    workflowRepository.saveAndFlush(applicationToUser_message);*/
		response.put(4,"APPLICATION ADDED USER ORDER INTO RECORD");

		/* 4: APPLICATION SHARES DELIVERY DETAILS TO DELIVERER */
		applicationToDeliverer_message = pubSubUtil.pubSubWorkflow(session, applicationDelivererSubscriber, applicationQueueName,
				new UserDetails(userToApplication_message.getOrderId(), userToApplication_message.getUsername(), 0,
						userToApplication_message.getDeliveryStatus(),
						userToApplication_message.getDeliveryLocation()));
		response.put(5,"APPLICATION TO DELIVERER MESSAGE- ORDERID: "+ applicationToDeliverer_message.getOrderId() + ", OTP: " + applicationToDeliverer_message.getOtp()+ ", DeliveryStatus: " + applicationToDeliverer_message.getDeliveryStatus());

		/* 5: USER SHARES OTP TO DELIVERER */
		userToDeliverer_message = pubSubUtil.pubSubWorkflow(session, userDelivererSubscriber, userQueueName,
				new UserDetails(applicationToUser_message.getOrderId(), applicationToUser_message.getUsername(),
						applicationToUser_message.getOtp(), applicationToUser_message.getDeliveryStatus(),
						applicationToUser_message.getDeliveryLocation()));
		response.put(6, "USER TO DELIVERER MESSAGE       - ORDERID: " + userToDeliverer_message.getOrderId()+ ", OTP: " + userToDeliverer_message.getOtp() + ", DeliveryStatus: "+ userToDeliverer_message.getDeliveryStatus());
		System.out.println();

		/* 6: DELIVERER TO APPLICATION FOR OTP VERIFICATION */
		delivererToApplication_message = pubSubUtil.pubSubWorkflow(session, delivererApplicationSubscriber, delivererQueueName,
				new UserDetails(userToDeliverer_message.getOrderId(), userToDeliverer_message.getUsername(),
						userToDeliverer_message.getOtp(), userToDeliverer_message.getDeliveryStatus(),
						userToDeliverer_message.getDeliveryLocation()));
		response.put(7, "DELIVERER TO APPLICATION MESSAGE- ORDERID: "+ delivererToApplication_message.getOrderId() + ", OTP: " + delivererToApplication_message.getOtp()+ ", DeliveryStatus: " + delivererToApplication_message.getDeliveryStatus());

		/* 7: APPLICATION VERIFIES OTP WITH USER RECORD AND UPDATE DELIVERY STATUS */
		/*UserDetails recordData = workflowRepository.findByOrderId(delivererToApplication_message.getOrderId());*/
		UserDetails recordData =userDetailsDao.getUserDetails(delivererToApplication_message.getOrderId());
		
		if (delivererToApplication_message.getOtp() == recordData.getOtp()
				&& recordData.getDeliveryStatus() != "DELIVERED") {
			deliveryStatus = "DELIVERED";
			
			response.put(8, "APPLICATION VERIFICATION FOR DELIVERY STATUS: " + deliveryStatus);

		} else {
			deliveryStatus = "FAILED";

			response.put(8, "APPLICATION VERIFICATION FOR DELIVERY STATUS: " + deliveryStatus);
		}
		userDetailsDao.update(recordData.getOrderId(), deliveryStatus);

		UserDetails updatedData = userDetailsDao.getUserDetails(delivererToApplication_message.getOrderId());
		/* 8: APPLICATION UPDATE DELIVERER TO DELIVER ORDER */
		applicationToDeliverer_message = pubSubUtil.pubSubWorkflow(session, applicationDelivererSubscriber, applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(), delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(), updatedData.getDeliveryStatus(), delivererToApplication_message.getDeliveryLocation()));
		response.put(9, "UPDATE DELIVERER MESSAGE        - ORDERID: " + applicationToDeliverer_message.getOrderId()+ ", OTP: " + applicationToDeliverer_message.getOtp() + ", DeliveryStatus: "+ applicationToDeliverer_message.getDeliveryStatus());

		/* 9: APPLICATION UPDATE USER FOR DELIVERED ORDER */
		applicationToUser_message = pubSubUtil.pubSubWorkflow(session, applicationUserSubscriber, applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(), delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(), updatedData.getDeliveryStatus(), delivererToApplication_message.getDeliveryLocation()));
		response.put(10, "UPDATE USER MESSAGE             - ORDERID: " + applicationToUser_message.getOrderId() + ", OTP: "+ applicationToUser_message.getOtp() + ", DeliveryStatus: "+ applicationToUser_message.getDeliveryStatus());

		return response;
	}


	public AQSession createSession() throws ClassNotFoundException, SQLException, AQException, JMSException {

		AQSession aq_sess = null;

		Class.forName("oracle.AQ.AQOracleDriver");
		aq_sess = AQDriverManager.createAQSession(url);

		System.out.println("Successfully created AQSession ");

		return aq_sess;
	}

	public AQQueue createQueue(AQSession session, String username, String queueTable, String queueName)
			throws JMSException, AQException {

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("SYS.AQ$_JMS_TEXT_MESSAGE");
		AQQueueProperty queue_prop = new AQQueueProperty();
		qtable_prop.setMultiConsumer(true);

		AQQueueTable qtable = ((AQSession) session).createQueueTable(username, queueTable, qtable_prop);
		AQQueue queue = session.createQueue(qtable, queueName, queue_prop);

		queue.start(true, true);
		System.out.println("Create Queue success QueueName : " + queueName);

		return queue;
	}

	public UserDetails enqueueDequeueMessage(TopicSession session, String subscriberName, String queueName, UserDetails user)
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

}
