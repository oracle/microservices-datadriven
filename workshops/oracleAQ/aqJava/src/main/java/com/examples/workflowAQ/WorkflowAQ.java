package com.examples.workflowAQ;


import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import javax.jms.JMSException;
import javax.jms.Topic;
import javax.jms.TopicSession;
import javax.jms.TopicSubscriber;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.examples.config.ConfigData;
import com.examples.config.ConstantName;
import com.examples.dao.UserDetails;
import com.examples.dao.UserDetailsDao;
import com.examples.util.pubSubUtil;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.AQ.AQException;
import oracle.AQ.AQQueue;
import oracle.AQ.AQQueueProperty;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.AQ.AQSession;
import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;

@Service
public class WorkflowAQ {

	@Autowired
	UserDetailsDao userDetailsDao;
	
	@Autowired(required=true)
	private ConfigData configData;

	@Autowired(required=true)
	private pubSubUtil pubSubUtil;
	
	@Autowired(required = true)
	private ConstantName constantName;
	
	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;

	ObjectMapper mapper = new ObjectMapper();
	Random rnd = new Random();

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
		
		/* Setup */
		AQSession qsession = configData.queueDataSourceConnection();
		createQueue(qsession, username, constantName.aq_userQueueTable, constantName.aq_userQueueName);
		createQueue(qsession, username, constantName.aq_delivererQueueTable, constantName.aq_delivererQueueName);
		createQueue(qsession, username, constantName.aq_applicationQueueTable, constantName.aq_applicationQueueName);
		
		TopicSession session = configData.topicDataSourceConnection();
		response.put(1, "Topic Connection created.");
		
		/* 1: USER PLACED OREDER ON APPLICATION */
		userToApplication_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_userApplicationSubscriber, constantName.aq_userQueueName,new UserDetails(rnd.nextInt(99999), "DBUSER", 0, "Pending", "US"));
		response.put(2,"USER ORDER MESSAGE              - ORDERID: " + userToApplication_message.getOrderId() + ", OTP: "
				+ userToApplication_message.getOtp() + ", DeliveryStatus: "
				+ userToApplication_message.getDeliveryStatus());

		/* 2: APPLICATION SHARES OTP TO USER */
		applicationToUser_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_applicationUserSubscriber, constantName.aq_applicationQueueName,
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
		applicationToDeliverer_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_applicationDelivererSubscriber, constantName.aq_applicationQueueName,
				new UserDetails(userToApplication_message.getOrderId(), userToApplication_message.getUsername(), 0,
						userToApplication_message.getDeliveryStatus(),
						userToApplication_message.getDeliveryLocation()));
		response.put(5,"APPLICATION TO DELIVERER MESSAGE- ORDERID: "+ applicationToDeliverer_message.getOrderId() + ", OTP: " + applicationToDeliverer_message.getOtp()+ ", DeliveryStatus: " + applicationToDeliverer_message.getDeliveryStatus());

		/* 5: USER SHARES OTP TO DELIVERER */
		userToDeliverer_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_userDelivererSubscriber, constantName.aq_userQueueName,
				new UserDetails(applicationToUser_message.getOrderId(), applicationToUser_message.getUsername(),
						applicationToUser_message.getOtp(), applicationToUser_message.getDeliveryStatus(),
						applicationToUser_message.getDeliveryLocation()));
		response.put(6, "USER TO DELIVERER MESSAGE       - ORDERID: " + userToDeliverer_message.getOrderId()+ ", OTP: " + userToDeliverer_message.getOtp() + ", DeliveryStatus: "+ userToDeliverer_message.getDeliveryStatus());
		System.out.println();

		/* 6: DELIVERER TO APPLICATION FOR OTP VERIFICATION */
		delivererToApplication_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_delivererApplicationSubscriber, constantName.aq_delivererQueueName,
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
		applicationToDeliverer_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_applicationDelivererSubscriber, constantName.aq_applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(), delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(), updatedData.getDeliveryStatus(), delivererToApplication_message.getDeliveryLocation()));
		response.put(9, "UPDATE DELIVERER MESSAGE        - ORDERID: " + applicationToDeliverer_message.getOrderId()+ ", OTP: " + applicationToDeliverer_message.getOtp() + ", DeliveryStatus: "+ applicationToDeliverer_message.getDeliveryStatus());

		/* 9: APPLICATION UPDATE USER FOR DELIVERED ORDER */
		applicationToUser_message = pubSubUtil.pubSubWorkflowAQ(session, constantName.aq_applicationUserSubscriber, constantName.aq_applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(), delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(), updatedData.getDeliveryStatus(), delivererToApplication_message.getDeliveryLocation()));
		response.put(10, "UPDATE USER MESSAGE             - ORDERID: " + applicationToUser_message.getOrderId() + ", OTP: "+ applicationToUser_message.getOtp() + ", DeliveryStatus: "+ applicationToUser_message.getDeliveryStatus());

		return response;
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

	
}
