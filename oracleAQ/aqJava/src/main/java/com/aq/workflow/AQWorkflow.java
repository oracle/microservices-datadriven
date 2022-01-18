package com.aq.workflow;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Random;

import javax.jms.JMSException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.aq.config.UserDetails;
import com.aq.dto.WorkflowRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import oracle.AQ.AQAgent;
import oracle.AQ.AQDequeueOption;
import oracle.AQ.AQDriverManager;
import oracle.AQ.AQEnqueueOption;
import oracle.AQ.AQException;
import oracle.AQ.AQMessage;
import oracle.AQ.AQQueue;
import oracle.AQ.AQQueueProperty;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.AQ.AQRawPayload;
import oracle.AQ.AQSession;

@Service
public class AQWorkflow {

	@Autowired
	private WorkflowRepository workflowRepository;

	@Value("${spring.datasource.username}")
	private String username;

	@Value("${spring.datasource.password}")
	private String password;

	@Value("${spring.datasource.url}")
	private String jdbcURL;

	ObjectMapper mapper = new ObjectMapper();

	String userAQQueueTable = "java_userQueueTable";
	String deliAQQueueTable = "java_deliQueueTable";
	String appAQQueueTable = "java_appQueueTable";

	String userAQQueueName = "java_userQueueName";
	String deliAQQueueName = "java_deliQueueName";
	String appAQQueueName = "java_appQueueName";

	String userSubscriber = "java_userSubscriber";
	String deliSubscriber = "java_deliSubscriber";
	String appSubscriber = "java_appSubscriber";

	public String aqWorkflow() throws JMSException, AQException, SQLException, ClassNotFoundException,
			JsonMappingException, JsonProcessingException {

		AQSession qsession = null;
		UserDetails userDetails = null;
		String deliveryStatus;

		/* Setup */
		qsession = createSession();
		AQQueue userQueue = createQueue(qsession, username, userAQQueueTable, userAQQueueName, userSubscriber);
		AQQueue deliQueue = createQueue(qsession, username, deliAQQueueTable, deliAQQueueName, deliSubscriber);
		AQQueue appQueue = createQueue(qsession, username, appAQQueueTable, appAQQueueName, appSubscriber);

		Random rnd = new Random();
		int otp = rnd.nextInt(9999);
		int orderId = rnd.nextInt(999);

		/* Step 1: Application shared order details to USER */
		userDetails = new UserDetails(orderId, "DBUSER", otp, "PENDING", "US");
		enqueueMessages(qsession, userQueue, userDetails);
		UserDetails userMessage = dequeueMessages(userQueue, userSubscriber);
		System.out.println("Step 1: Application shared order details to USER");

		/* Step 2: Application saved order details to DATABASE */
		workflowRepository.saveAndFlush(userDetails);
		System.out.println("Step 2: Application saved order details to DATABASE");

		/* Step 3: Application shared delivery details to DELIVERER */
		userDetails = new UserDetails(userMessage.getOrderId(), userMessage.getUsername(), 0,
				userMessage.getDeliveryStatus(), userMessage.getDeliveryLocation());
		enqueueMessages(qsession, deliQueue, userDetails);
		UserDetails deliMessage = dequeueMessages(deliQueue, deliSubscriber);
		System.out.println("Step 3: Application shared delivery details to DELIVERER");

		/* Step 4: Deliverer shared the user OTP to APPLICATION */
		userDetails = new UserDetails(deliMessage.getOrderId(), deliMessage.getUsername(), userMessage.getOtp(),
				deliMessage.getDeliveryStatus(), deliMessage.getDeliveryLocation());
		enqueueMessages(qsession, appQueue, userDetails);
		UserDetails appMessage = dequeueMessages(appQueue, appSubscriber);
		System.out.println("Step 4: Deliverer shared the user OTP to APPLICATION");

		/* Step 5: Application verifies OTP from USER_OTP with DATABASE_OTP */
		UserDetails existingData = workflowRepository.findByOrderId(appMessage.getOrderId());

		if (appMessage.getOtp() == existingData.getOtp()) {
			existingData.setDeliveryStatus("DELIVERED");
			deliveryStatus = "DELIVERED";
		} else {
			existingData.setDeliveryStatus("FAILED");
			deliveryStatus = "FAILED";
		}
		System.out.println("Step 5: Application verifies OTP from USER_OTP with DATABASE_OTP");

		/* Step 6: APPLICATION updated DELIVERY_STATUS in DATABASE */
		workflowRepository.saveAndFlush(existingData);
		System.out.println("Step 6: APPLICATION updated DELIVERY_STATUS in DATABASE: " + deliveryStatus);

		UserDetails updatedData = workflowRepository.findByOrderId(appMessage.getOrderId());
		userDetails = new UserDetails(appMessage.getOrderId(), appMessage.getUsername(), appMessage.getOtp(),
				updatedData.getDeliveryStatus(), appMessage.getDeliveryLocation());

		/* Step 7: APPLICATION updated DELIVERY_STATUS to DELIVERER: */
		enqueueMessages(qsession, deliQueue, userDetails);
		UserDetails updateDeliMessage = dequeueMessages(deliQueue, deliSubscriber);
		System.out.println(
				"Step 7: APPLICATION updated DELIVERY_STATUS to DELIVERER: " + updatedData.getDeliveryStatus());

		/* Step 8: APPLICATION updated DELIVERY_STATUS to USER */
		enqueueMessages(qsession, userQueue, userDetails);
		UserDetails updateUserMessage = dequeueMessages(userQueue, userSubscriber);
		System.out.println("Step 8: APPLICATION updated DELIVERY_STATUS to USER: " + updatedData.getDeliveryStatus());

		qsession.close();
		return deliveryStatus;
	}

	public AQSession createSession() throws ClassNotFoundException, SQLException, AQException, JMSException {
		Connection db_conn;
		AQSession aq_sess = null;

		Class.forName("oracle.jdbc.driver.OracleDriver");
		db_conn = DriverManager.getConnection(jdbcURL, username, password);
		db_conn.setAutoCommit(true);

		Class.forName("oracle.AQ.AQOracleDriver");
		aq_sess = AQDriverManager.createAQSession(db_conn);

		System.out.println("Successfully created AQSession ");

		return aq_sess;
	}

	public AQQueue createQueue(AQSession session, String username, String queueTable, String queueName,
			String subscriberName) throws JMSException, AQException {

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();
		qtable_prop.setMultiConsumer(true);

		AQQueueTable qtable = ((AQSession) session).createQueueTable(username, queueTable, qtable_prop);
		AQQueue queue = session.createQueue(qtable, queueName, queue_prop);

		queue.start(true, true);
		System.out.println("Create Queue success QueueName : " + queueName);

		AQAgent subscriber = new AQAgent(subscriberName, null, 0);
		queue.addSubscriber(subscriber, null);
		System.out.println("Subscriber : " + subscriberName);

		return queue;
	}

	public void enqueueMessages(AQSession qsession, AQQueue queue, UserDetails user)
			throws JMSException, java.sql.SQLException, AQException, JsonProcessingException {

		String jsonString = mapper.writeValueAsString(user);

		AQMessage message = queue.createMessage();
		byte[] b_array = jsonString.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);
		message.setRawPayload(raw_payload);
		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		System.out.println("Enqueue Message2 Queue : " + message.toString());

	}

	public UserDetails dequeueMessages(AQQueue queue, String subscriberName)
			throws AQException, JMSException, JsonMappingException, JsonProcessingException {
		AQMessage message = queue.createMessage();
		AQDequeueOption dequeueOption = new AQDequeueOption();

		dequeueOption.setDequeueMode(AQDequeueOption.DEQUEUE_REMOVE);
		dequeueOption.setConsumerName(subscriberName);
		dequeueOption.setWaitTime(10);
		message = queue.dequeue(dequeueOption);

		AQRawPayload raw_payload = message.getRawPayload();
		byte[] b_array = raw_payload.getBytes();

		String ret_value = new String(b_array);
		UserDetails user = mapper.readValue(ret_value, UserDetails.class);

		System.out.println("Dequeue Message :" + ret_value);

		return user;
	}

}
