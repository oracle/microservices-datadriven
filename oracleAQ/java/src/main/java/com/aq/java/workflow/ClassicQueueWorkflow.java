package com.aq.java.workflow;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Random;

import javax.jms.JMSException;

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
import com.aq.java.config.JsonUtils;
import com.aq.java.config.UserDetails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ClassicQueueWorkflow {

	@Value("${spring.datasource.username}")
	private String username;

	@Value("${spring.datasource.password}")
	private String password;

	@Value("${spring.datasource.url}")
	private String jdbcURL;

	String userAQQueueTable = "java_userQueueTable";
	String deliAQQueueTable = "java_deliQueueTable";
	String appAQQueueTable = "java_appQueueTable";

	String userAQQueueName = "java_userQueueName";
	String deliAQQueueName = "java_deliQueueName";
	String appAQQueueName = "java_appQueueName";

	String userSubscriber = "java_userSubscriber";
	String deliSubscriber = "java_deliSubscriber";
	String appSubscriber = "java_appSubscriber";

	private String query = null;

	// @PostConstruct
	public String lab2() throws JMSException, AQException, SQLException, ClassNotFoundException {

		AQSession qsession = null;

		// Setup
		qsession = createSession();
		AQQueue userQueue = setup(qsession, username, userAQQueueTable, userAQQueueName);
		AQQueue deliQueue = setup(qsession, username, deliAQQueueTable, deliAQQueueName);
		System.out.println("        Setup is complete");

		// Step 1: Enqueue user
		Random rnd = new Random();
		int otp = rnd.nextInt(9999);
		int orderId = rnd.nextInt(999);

		UserDetails userDetails = new UserDetails(orderId, "DBUSER", otp, "Pending", "US");
		String query = "insert into USERDETAILS values('" + orderId + "', '" + userDetails.getUsername() + "', '" + otp
				+ "', '" + userDetails.getDeliveryStatus() + "', '" + userDetails.getDeliveryLocation() + "')";
		databaseOperations(query);
		enqueueMessages(qsession, userQueue, userDetails, userSubscriber);
		System.out.println("Step 1: Enqueue user is complete.");

		// Step 2: Enqueue deli boy
		UserDetails deliDetails = new UserDetails(userDetails.getOrderId(), null, 0, userDetails.getDeliveryStatus(),
				userDetails.getDeliveryLocation());
		enqueueMessages(qsession, deliQueue, deliDetails, deliSubscriber);
		System.out.println("Step 2: Enqueue deli is complete.");

		// Step 3: Dequeue User
		System.out.println("Step 3: Dequeue user initiated.......");
		String status = dequeueMessages(qsession, username, userQueue, deliQueue, userDetails, deliDetails);
		System.out.println(".......All dequeue is complete.......");

		cleanup(qsession, username);
		qsession.close();
		// qconn.close();
		System.out.println("End of Delivery");

		return status;
	}

	public AQSession createSession() throws ClassNotFoundException, SQLException, AQException, JMSException {
		Connection db_conn;
		AQSession aq_sess = null;

		Class.forName("oracle.jdbc.driver.OracleDriver");
		db_conn = DriverManager.getConnection(jdbcURL, username, password);
		db_conn.setAutoCommit(true);

		Class.forName("oracle.AQ.AQOracleDriver");
		aq_sess = AQDriverManager.createAQSession(db_conn);

		System.out.println("        Successfully created AQSession ");

		return aq_sess;
	}

	public AQQueue setup(AQSession session, String username, String queueTable, String queueName)
			throws JMSException, AQException {

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();
		qtable_prop.setMultiConsumer(true);

		AQQueueTable qtable = ((AQSession) session).createQueueTable(username, queueTable, qtable_prop);
		AQQueue queue = session.createQueue(qtable, queueName, queue_prop);

		queue.start(true, true);
		System.out.println("        Successful createQueue : " + queueName);

		return queue;
	}

	public void enqueueMessages(AQSession qsession, AQQueue queue, UserDetails user, String subscriberName)
			throws JMSException, java.sql.SQLException, AQException {

		AQAgent subscriber = new AQAgent(subscriberName, null, 0);
		queue.addSubscriber(subscriber, null);
		// queue.addSubscriber(subscriber, "priority < 2");

		System.out.println("        Add Subscriber : " + subscriberName);
		String jsonString = JsonUtils.writeValueAsString(user);
		AQMessage message = queue.createMessage();

		byte[] b_array = jsonString.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		System.out.println("        Enqueue successfully for " + queue.getName());
	}

	public String dequeueMessages(AQSession qsession, String username, AQQueue userQueue, AQQueue deliQueue,
			UserDetails userData, UserDetails deliData)
			throws JMSException, java.lang.ClassNotFoundException, java.sql.SQLException, AQException {
		String status;
		AQDequeueOption userReceiver = new AQDequeueOption();
		AQDequeueOption deliReceiver = new AQDequeueOption();
		AQDequeueOption appReceiver = new AQDequeueOption();

		AQMessage userMessage = userQueue.createMessage();
		AQMessage deliMessage = deliQueue.createMessage();
		AQMessage appMessage = deliQueue.createMessage();

		userReceiver.setConsumerName(userSubscriber);
		deliReceiver.setConsumerName(deliSubscriber);
		appReceiver.setConsumerName(appSubscriber);

		AQRawPayload raw_payload = null;
		byte[] b_array;

		// Step 4: Dequeue browse for user
		userReceiver.setDequeueMode(AQDequeueOption.DEQUEUE_BROWSE);
		userReceiver.setWaitTime(10);
		userMessage = userQueue.dequeue(userReceiver);
		raw_payload = userMessage.getRawPayload();
		b_array = raw_payload.getBytes();
		String userBrowse_value = new String(b_array);
		UserDetails userDetails = JsonUtils.read(userBrowse_value, UserDetails.class);
		System.out.println("Step 4: Dequeue Browse for user: [" + userBrowse_value + "]");

		// Step 5: Dequeue remove Delivery boy
		deliReceiver.setDequeueMode(AQDequeueOption.DEQUEUE_REMOVE);
		deliMessage = deliQueue.dequeue(deliReceiver);
		raw_payload = deliMessage.getRawPayload();
		b_array = raw_payload.getBytes();
		String deli_value = new String(b_array);
		System.out.println("Step 5: Dequeue deli receiver: " + deli_value);

		// Step 6: Enqueue for app by delivery boy
		AQQueue appQueue = setup(qsession, username, appAQQueueTable, appAQQueueName);
		deliData.setOtp(userDetails.getOtp());
		enqueueMessages(qsession, appQueue, deliData, appSubscriber);
		System.out.println("Step 6: Enqueue for app : " + deliQueue.getName());

		// Step 7: Dequeue browse by app
		appReceiver.setDequeueMode(AQDequeueOption.DEQUEUE_BROWSE);
		appReceiver.setWaitTime(10);
		appMessage = appQueue.dequeue(appReceiver);
		raw_payload = appMessage.getRawPayload();
		b_array = raw_payload.getBytes();
		String appBrowse_value = new String(b_array);
		System.out.println("Step 7: Dequeue Browse by app:  [" + appBrowse_value + "]");

		UserDetails deliDetails = JsonUtils.read(appBrowse_value, UserDetails.class);
		query = "UPDATE USERDETAILS set Delivery_Status = 'DELIVERED' WHERE ORDERID = '" + deliDetails.getOrderId()
				+ "' AND OTP = '" + deliDetails.getOtp() + "'";

		// Step 8: Match user OTP and app OTP
		if (userDetails.getOtp() == deliDetails.getOtp()) {
			System.out.println("Step 8: OTP matched where user_OTP: " + userDetails.getOtp() + " and App_OTP:  "
					+ deliDetails.getOtp());

			// Step 9: dequeue remove
			userReceiver.setDequeueMode(AQDequeueOption.DEQUEUE_REMOVE);
			userMessage = userQueue.dequeue(userReceiver);
			raw_payload = userMessage.getRawPayload();
			b_array = raw_payload.getBytes();
			String user_value = new String(b_array);
			System.out.println("Step 9.1: Dequeue user receiver: " + user_value);

			appReceiver.setDequeueMode(AQDequeueOption.DEQUEUE_REMOVE);
			appMessage = appQueue.dequeue(appReceiver);
			raw_payload = appMessage.getRawPayload();
			b_array = raw_payload.getBytes();
			String app_value = new String(b_array);
			System.out.println("Step 9.2: Dequeue app receiver: " + app_value);

			System.out.println("          Dequeue ends for all receivers.....");

			// Step 10: Update DB
			query = "UPDATE USERDETAILS set Delivery_Status = 'DELIVERED' WHERE ORDERID = '" + deliDetails.getOrderId()
					+ "' AND OTP = '" + deliDetails.getOtp() + "'";
			databaseOperations(query);
			System.out.println("Step 10: Update Delivery Status as DELIVERED in DB");

			status = "Success";

		} else {
			// Step 10: Update DB
			query = "UPDATE USERDETAILS set Delivery_Status = 'FAILED' WHERE ORDERID = '" + deliDetails.getOrderId()
					+ "' AND OTP = '" + deliDetails.getOtp() + "'";
			databaseOperations(query);
			System.out.println("Step 10: Update Delivery Status as FAILED in DB");

			status = "Failed";
		}
		return status;
	}

	private void cleanup(AQSession qsession, String user) throws JMSException, AQException {

		AQQueueTable userTable = qsession.getQueueTable(user, userAQQueueTable);
		AQQueueTable deliTable = qsession.getQueueTable(user, deliAQQueueTable);

		if (userTable != null && deliTable != null) {
			userTable.drop(true);
			deliTable.drop(true);
			System.out.println("Queue tables dropped successfully");
		} else {
			System.out.println("Queue tables dropped failed");
		}
	}

	public void databaseOperations(String queryData) throws ClassNotFoundException, SQLException {
		Class.forName("oracle.jdbc.driver.OracleDriver");
		Connection con = DriverManager.getConnection(jdbcURL, username, password);
		Statement stmt = con.createStatement();

		int x = stmt.executeUpdate(queryData);
		if (x > 0) {
			System.out.println("        Successfully executed database operation");
		} else {
			System.out.println("        Failed database operation");
		}
		con.close();
	}
}
