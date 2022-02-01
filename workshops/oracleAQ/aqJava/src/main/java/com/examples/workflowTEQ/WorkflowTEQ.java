package com.examples.workflowTEQ;

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
public class WorkflowTEQ {

	@Autowired
	private WorkflowRepository workflowRepository;

	@Value("${username}")
	private String username;

//	@Value("${spring.datasource.password}")
//	private String password;

	@Value("${spring.datasource.url}")
	private String jdbcURL;

	ObjectMapper mapper = new ObjectMapper();
	Random rnd = new Random();

	String userQueueName = "java_UserQueue";
	String userApplicationSubscriber = "java_userAppSubscriber";
	String userDelivererSubscriber = "java_userDelivererSubscriber";

	String delivererQueueName = "java_DelivererQueue";
	String delivererUserSubscriber = "java_delivererUserSubscriber";
	String delivererApplicationSubscriber = "java_delivererApplicationSubscriber";

	String applicationQueueName = "java_ApplicationQueue";
	String applicationUserSubscriber = "java_appUserSubscriber";
	String applicationDelivererSubscriber = "java_appDelivererSubscriber";

	UserDetails userToApplication_message;
	UserDetails userToDeliverer_message;
	UserDetails delivererToUser_message;
	UserDetails delivererToApplication_message;
	UserDetails applicationToUser_message;
	UserDetails applicationToDeliverer_message;

	public String pubSubWorkflowTEQ() throws JMSException, AQException, SQLException, ClassNotFoundException,
			JsonMappingException, JsonProcessingException {
		String deliveryStatus = "Success";

		OracleDataSource ds = new OracleDataSource();

		ds.setUser(username);
		//ds.setPassword(password);
		ds.setURL(jdbcURL);
		Class.forName("oracle.AQ.AQOracleDriver");

		TopicConnectionFactory tc_fact = AQjmsFactory.getTopicConnectionFactory(ds);
		TopicConnection conn = null;

		conn = tc_fact.createTopicConnection();
		conn.start();
		TopicSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);
		
		/* 1: USER PLACED OREDER ON APPLICATION */
		userToApplication_message = enqueueDequeueMessage(session, userApplicationSubscriber, userQueueName,
				new UserDetails(rnd.nextInt(999), "DBUSER", 0, "Pending", "US"));
		
		System.out.println("USER ORDER MESSAGE              - ORDERID: " + userToApplication_message.getOrderId() + ", OTP: "
				+ userToApplication_message.getOtp() + ", DeliveryStatus: "
				+ userToApplication_message.getDeliveryStatus());
		System.out.println();
		/* 2: APPLICATION SHARES OTP TO USER */
		applicationToUser_message = enqueueDequeueMessage(session, applicationUserSubscriber, applicationQueueName,
				new UserDetails(userToApplication_message.getOrderId(), userToApplication_message.getUsername(),
						rnd.nextInt(9999), userToApplication_message.getDeliveryStatus(),
						userToApplication_message.getDeliveryLocation()));
	

		System.out.println("APPLICATION TO USER MESSAGE     - ORDERID: " + applicationToUser_message.getOrderId()
				+ ", OTP: " + applicationToUser_message.getOtp() + ", DeliveryStatus: "
				+ applicationToUser_message.getDeliveryStatus());
		System.out.println();

		/* 3: APPLICATION CREATES AN USER RECORD */
		workflowRepository.saveAndFlush(applicationToUser_message);

		System.out.println("APPLICATION ADDED USER ORDER INTO RECORD");
		System.out.println();

		/* 4: APPLICATION SHARES DELIVERY DETAILS TO DELIVERER */
		applicationToDeliverer_message = enqueueDequeueMessage(session, applicationDelivererSubscriber, applicationQueueName,
				new UserDetails(userToApplication_message.getOrderId(), userToApplication_message.getUsername(), 0,
						userToApplication_message.getDeliveryStatus(),
						userToApplication_message.getDeliveryLocation()));
		
		System.out.println("APPLICATION TO DELIVERER MESSAGE- ORDERID: "+ applicationToDeliverer_message.getOrderId() + ", OTP: " + applicationToDeliverer_message.getOtp()+ ", DeliveryStatus: " + applicationToDeliverer_message.getDeliveryStatus());
		System.out.println();

		/* 5: USER SHARES OTP TO DELIVERER */
		userToDeliverer_message = enqueueDequeueMessage(session, userDelivererSubscriber, userQueueName,
				new UserDetails(applicationToUser_message.getOrderId(), applicationToUser_message.getUsername(),
						applicationToUser_message.getOtp(), applicationToUser_message.getDeliveryStatus(),
						applicationToUser_message.getDeliveryLocation()));
		

		System.out.println("USER TO DELIVERER MESSAGE       - ORDERID: " + userToDeliverer_message.getOrderId()+ ", OTP: " + userToDeliverer_message.getOtp() + ", DeliveryStatus: "+ userToDeliverer_message.getDeliveryStatus());
		System.out.println();

		/* 6: DELIVERER TO APPLICATION FOR OTP VERIFICATION */
		delivererToApplication_message = enqueueDequeueMessage(session, delivererApplicationSubscriber, delivererQueueName,
				new UserDetails(userToDeliverer_message.getOrderId(), userToDeliverer_message.getUsername(),
						userToDeliverer_message.getOtp(), userToDeliverer_message.getDeliveryStatus(),
						userToDeliverer_message.getDeliveryLocation()));
		

		System.out.println("DELIVERER TO APPLICATION MESSAGE- ORDERID: "+ delivererToApplication_message.getOrderId() + ", OTP: " + delivererToApplication_message.getOtp()+ ", DeliveryStatus: " + delivererToApplication_message.getDeliveryStatus());
		System.out.println();

		/* 7: APPLICATION VERIFIES OTP WITH USER RECORD AND UPDATE DELIVERY STATUS */
		UserDetails recordData = workflowRepository.findByOrderId(delivererToApplication_message.getOrderId());

		if (delivererToApplication_message.getOtp() == recordData.getOtp()
				&& recordData.getDeliveryStatus() != "DELIVERED") {
			recordData.setDeliveryStatus("DELIVERED");
			deliveryStatus = "DELIVERED";
			
			System.out.println("APPLICATION VERIFICATION FOR DELIVERY STATUS: " + deliveryStatus);
			System.out.println();

		} else {
			recordData.setDeliveryStatus("FAILED");
			deliveryStatus = "FAILED";

			System.out.println("APPLICATION VERIFICATION FOR DELIVERY STATUS: " + deliveryStatus);
			System.out.println();

		}
		workflowRepository.saveAndFlush(recordData);

		UserDetails updatedData = workflowRepository.findByOrderId(delivererToApplication_message.getOrderId());
		/* 8: APPLICATION UPDATE DELIVERER TO DELIVER ORDER */
		applicationToDeliverer_message = enqueueDequeueMessage(session, applicationDelivererSubscriber, applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(),
						delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(),
						updatedData.getDeliveryStatus(),
						delivererToApplication_message.getDeliveryLocation()));
		System.out.println("UPDATE DELIVERER MESSAGE        - ORDERID: " + applicationToDeliverer_message.getOrderId()+ ", OTP: " + applicationToDeliverer_message.getOtp() + ", DeliveryStatus: "+ applicationToDeliverer_message.getDeliveryStatus());
		System.out.println();

		/* 9: APPLICATION UPDATE USER FOR DELIVERED ORDER */
		applicationToUser_message = enqueueDequeueMessage(session, applicationUserSubscriber, applicationQueueName,
				new UserDetails(delivererToApplication_message.getOrderId(),
						delivererToApplication_message.getUsername(), delivererToApplication_message.getOtp(),
						updatedData.getDeliveryStatus(),
						delivererToApplication_message.getDeliveryLocation()));
		System.out.println("UPDATE USER MESSAGE             - ORDERID: " + applicationToUser_message.getOrderId() + ", OTP: "+ applicationToUser_message.getOtp() + ", DeliveryStatus: "+ applicationToUser_message.getDeliveryStatus());
		System.out.println();

		return deliveryStatus;
	}

	public UserDetails enqueueDequeueMessage(TopicSession session, String subscriberName, String queueName, UserDetails user)
			throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {

		Topic topic = ((AQjmsSession) session).getTopic(username, queueName);
		AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);
		TopicSubscriber topicSubscriber = (TopicSubscriber) ((AQjmsSession) session).createDurableSubscriber(topic,subscriberName);

		String jsonString = mapper.writeValueAsString(user);
		System.out.println("------Publisher Message: "+jsonString);
		AQjmsTextMessage publisherMessage = (AQjmsTextMessage) session.createTextMessage(jsonString);
		publisher.publish(publisherMessage, new AQjmsAgent[] { new AQjmsAgent(subscriberName, null) });
        session.commit();

		AQjmsTextMessage subscriberMessage = (AQjmsTextMessage) topicSubscriber.receive(10);				
		UserDetails userData = mapper.readValue(subscriberMessage.getText(), UserDetails.class);
		System.out.println("------Subscriber Message: "+subscriberMessage.getText());

        session.commit();

		return userData;
	}

}
