package com.examples.enqueueDequeueAQ;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

import oracle.AQ.AQAgent;
import oracle.AQ.AQDequeueOption;
import oracle.AQ.AQDriverManager;
import oracle.AQ.AQEnqueueOption;
import oracle.AQ.AQException;
import oracle.AQ.AQMessage;
import oracle.AQ.AQMessageProperty;
import oracle.AQ.AQOracleSession;
import oracle.AQ.AQQueue;
import oracle.AQ.AQQueueProperty;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.AQ.AQRawPayload;
import oracle.AQ.AQSession;
import org.springframework.stereotype.Service;

@Service
public class EnqueueDequeueAQ {

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;
	
//	@Value("${password}")
//	private String password;
	
	@Autowired 
	DataSource ds;

	String oracleQueueTable = "java_QueueTable";
	String oracleQueueName = "java_QueueName";

	String oracleQueueTable_multi = "java_QueueTable_Multi";
	String oracleQueueName_multi = "java_QueueName_Multi";


	public String pointToPointAQ() {
		AQSession aq_sess = null;
		String status;
		try {
			aq_sess = createSession();

			createQueue(aq_sess);
			System.out.println("---------------createQueue successfully-------------------");

			useCreatedQueue(aq_sess);
			System.out.println("---------------useCreatedQueue successfully---------------");

			enqueueAndDequeue(aq_sess);
			System.out.println("---------------enqueueAndDequeue successfully-------------");

			multiuserQueue(aq_sess);
			System.out.println("---------------multiuserQueue successfully----------------");

			enqueueRAWMessages(aq_sess);
			System.out.println("---------------enqueueRAWMessages successfully------------");

			dequeueRawMessages(aq_sess);
			System.out.println("---------------dequeueRAWMessages successfully------------");

			dequeueMessagesBrowseMode(aq_sess);
			System.out.println("---------------dequeueMessagesBrowseMode successfully------");

			enqueueMessagesWithPriority(aq_sess);
			System.out.println("---------------enqueueMessagesWithPriority successfully----");

			status = "Success";

		} catch (Exception ex) {
			System.out.println("Exception-1: " + ex);
			ex.printStackTrace();
			status = "Failed";
		}
		return status;
	}

	public AQSession createSession() {
		Connection db_conn;
		AQSession aq_sess = null;
		try {
//			Class.forName("oracle.jdbc.driver.OracleDriver");
//			db_conn = DriverManager.getConnection(url, username );
//
//			System.out.println("JDBC Connection opened ");
//			db_conn.setAutoCommit(false);
			Class.forName("oracle.AQ.AQOracleDriver");

			/* Creating an AQ Session: */
			aq_sess = AQDriverManager.createAQSession(ds);

			System.out.println("Successfully created AQSession ");
		} catch (Exception ex) {
			System.out.println("Exception: " + ex);
			ex.printStackTrace();
		}
		return aq_sess;
	}

	public void createQueue(AQSession aq_sess) throws AQException {
		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueueTable q_table = aq_sess.createQueueTable(username, oracleQueueTable, qtable_prop);
		System.out.println("Successfully created classicRawQueueTable in  DBUSER schema");

		AQQueue queue = aq_sess.createQueue(q_table, oracleQueueName, queue_prop);
		System.out.println("Successfully created classicRawQueue in classicRawQueue");
	}

	public void useCreatedQueue(AQSession aq_sess) throws AQException {

		AQQueueTable q_table = aq_sess.getQueueTable(username, oracleQueueTable);
		System.out.println("Successful getQueueTable");

		AQQueue queue = aq_sess.getQueue(username, oracleQueueName);
		System.out.println("Successful getQueue" + queue.getQueueTableName() + "------" + queue.getName());
	}

	public void enqueueAndDequeue(AQSession aq_sess) throws AQException {

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		/* qtable_prop.setCompatible("8.1"); */

		AQQueueTable q_table = aq_sess.createQueueTable(username, "java_basicOracleQueueTable", qtable_prop);
		System.out.println("Successful createQueueTable");

		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueue queue = aq_sess.createQueue(q_table, "java_basicOracleQueueName", queue_prop);
		System.out.println("Successful createQueue");

		queue.start(true, true);
		System.out.println("Successful start queue");

		queue.grantQueuePrivilege("ENQUEUE", username);
		System.out.println("Successful grantQueuePrivilege");
	}

	public void multiuserQueue(AQSession aq_sess) throws AQException {

		AQAgent subs111, subs222;

		/* Creating a AQQueueTable property object (payload type - RAW): */
		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");

		/* Creating a new AQQueueProperty object: */
		AQQueueProperty queue_prop = new AQQueueProperty();

		/* Set multiconsumer flag to true: */
		qtable_prop.setMultiConsumer(true);

		/* Creating a queue table in DBUSER schema: */
		AQQueueTable q_table = aq_sess.createQueueTable(username, oracleQueueTable_multi, qtable_prop);
		System.out.println("Successful createQueueTable");

		AQQueue queue = aq_sess.createQueue(q_table, oracleQueueName_multi, queue_prop);
		System.out.println("Successful createQueue");

		/* Enable enqueue/dequeue on this queue: */
		queue.start();
		System.out.println("Successful start queue");

		/* Add subscribers to this queue: */
		subs111 = new AQAgent("GREEN_MULTI", null, 0);
		subs222 = new AQAgent("BLUE_MULTI", null, 0);

		queue.addSubscriber(subs111, null); /* no rule */
		System.out.println("Successful addSubscriber 111");

		queue.addSubscriber(subs222, "priority < 2"); /* with rule */
		System.out.println("Successful addSubscriber 222");
	}

	public void enqueueRAWMessages(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue-classicRawMultiUserQueue in DBUSER schema: */
		AQQueue queue = aq_sess.getQueue(username, oracleQueueName_multi);
		System.out.println("Successful getQueue");

		/* Creating a message to contain raw payload: */
		AQMessage message = queue.createMessage();

		/* Get handle to the AQRawPayload object and populate it with raw data: */
		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();

		raw_payload.setStream(b_array, b_array.length);

		/* Creating a AQEnqueueOption object with default options: */
		AQEnqueueOption enq_option = new AQEnqueueOption();

		/* Enqueue the message: */
		queue.enqueue(enq_option, message);

		db_conn.commit();
	}

	public void dequeueRawMessages(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();
		AQQueue queue = aq_sess.getQueue(username, oracleQueueName_multi);

		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);
		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		/* Creating a AQDequeueOption object with default options: */
		AQDequeueOption deq_option = new AQDequeueOption();

		/* Dequeue a message: */
		deq_option.setConsumerName("GREEN_MULTI");
		message = queue.dequeue(deq_option);

		/* Retrieve raw data from the message: */
		raw_payload = message.getRawPayload();

		b_array = raw_payload.getBytes();

		db_conn.commit();
	}

	public void dequeueMessagesBrowseMode(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue in DBUSER schema: */
		AQQueue queue = aq_sess.getQueue(username, oracleQueueName_multi);
		System.out.println("Successful getQueue");

		/* Creating a message to contain raw payload: */
		AQMessage message = queue.createMessage();

		/* Get handle to the AQRawPayload object and populate it with raw data: */

		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();

		queue.enqueue(enq_option, message);
		System.out.println("Successful enqueue");

		db_conn.commit();

		AQDequeueOption deq_option = new AQDequeueOption();

		deq_option.setConsumerName("GREEN_MULTI");

		/* Set dequeue mode to BROWSE: */
		deq_option.setDequeueMode(AQDequeueOption.DEQUEUE_BROWSE);

		/* Set wait time to 10 seconds: */
		deq_option.setWaitTime(10);

		/* Dequeue a message: */
		message = queue.dequeue(deq_option);

		/* Retrieve raw data from the message: */
		raw_payload = message.getRawPayload();
		b_array = raw_payload.getBytes();

		String ret_value = new String(b_array);
		System.out.println("Dequeued message: " + ret_value);

		db_conn.commit();
	}

	public void enqueueMessagesWithPriority(AQSession aq_sess) throws AQException, SQLException {

		String test_data;
		byte[] b_array;
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue in DBUSER schema: */
		AQQueue queue = aq_sess.getQueue(username, oracleQueueName_multi);
		System.out.println("Successful getQueue");

		/* Enqueue 5 messages with priorities with different priorities: */
		for (int i = 0; i < 5; i++) {
			/* Creating a message to contain raw payload: */
			AQMessage message = queue.createMessage();

			test_data = "Small_message_" + (i + 1); /* some test data */

			/* Get a handle to the AQRawPayload object and populate it with raw data */
			b_array = test_data.getBytes();

			AQRawPayload raw_payload = message.getRawPayload();
			raw_payload.setStream(b_array, b_array.length);

			/* Set message priority: */
			AQMessageProperty m_property = message.getMessageProperty();

			if (i < 2)
				m_property.setPriority(2);
			else
				m_property.setPriority(3);

			/* Creating a AQEnqueueOption object with default options: */
			AQEnqueueOption enq_option = new AQEnqueueOption();

			/* Enqueue the message: */
			queue.enqueue(enq_option, message);
			System.out.println("Successful enqueue");
		}
		db_conn.commit();
	}

}
