package com.examples.enqueueDequeueAQ;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import javax.jms.JMSException;
import javax.jms.Topic;
import javax.jms.TopicSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.examples.config.ConfigData;
import com.examples.config.ConstantName;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.examples.util.pubSubUtil;

import oracle.AQ.AQAgent;
import oracle.AQ.AQDequeueOption;
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
import oracle.jms.AQjmsSession;

@Service
public class EnqueueDequeueAQ {

	@Autowired(required = true)
	private pubSubUtil pubSubUtil;

	@Autowired(required = true)
	private ConfigData configData;
	
	@Autowired(required = true)
	private ConstantName constantName;

	@Value("${username}")
	private String username;

	public Map<Integer, String> pointToPointAQ() throws ClassNotFoundException, SQLException, AQException, JMSException {
		Map<Integer, String> response = new HashMap();

		AQSession aq_sess = configData.queueDataSourceConnection();

		createQueue(aq_sess);
		response.put(1, "Sample to create single-consumer Queue executed");

		useCreatedQueue(aq_sess);
		response.put(2, "Sample to use existing Queues executed");

		enqueueAndDequeue(aq_sess);
		response.put(3, "Sample to Enqueue and Dequeue single-consumer Queue executed");
		
		cleanupAQ(aq_sess, constantName.aq_createTable);
		cleanupAQ(aq_sess, constantName.aq_enqueueDequeueTable);
		response.put(4, "Sample to Cleanup single-consumer Queue executed");

		multiConsumerQueue(aq_sess);
		response.put(5, "Sample to create multi-consumer Queue executed");

		enqueueMultiConsumer(aq_sess);
		response.put(6, "Sample to create multi-consumer Enqueue executed");

		dequeueMultiConsumer(aq_sess);
		response.put(7, "Sample to create multi-consumer Dequeue executed");

		enqueueMultiConsumerWithPriority(aq_sess);
		response.put(8, "Sample to create multi-consumer Enqueue with Priority executed");

		dequeueMultiConsumerBrowseMode(aq_sess);
		response.put(9, "Sample to create multi-consumer Dequeue with Browse mode executed");
		
		cleanupAQ(aq_sess, constantName.aq_multiConsumerTable);
		response.put(10, "Sample to Cleanup multi-consumer Queue executed");

		return response;
	}

	public void createQueue(AQSession aq_sess) throws AQException {
		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueueTable q_table = aq_sess.createQueueTable(username, constantName.aq_createTable, qtable_prop);

		AQQueue queue = aq_sess.createQueue(q_table, constantName.aq_createQueue, queue_prop);
	}

	public void useCreatedQueue(AQSession aq_sess) throws AQException {

		AQQueueTable q_table = aq_sess.getQueueTable(username, constantName.aq_createTable);

		AQQueue queue = aq_sess.getQueue(username, constantName.aq_createQueue);
		System.out.println("Successful createQueue" + queue.getQueueTableName() + queue.getName());
	}

	public void enqueueAndDequeue(AQSession aq_sess) throws AQException, SQLException {

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");

		AQQueueTable q_table = aq_sess.createQueueTable(username, constantName.aq_enqueueDequeueTable, qtable_prop);
		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueue queue = aq_sess.createQueue(q_table, constantName.aq_enqueueDequeueQueue, queue_prop);
		queue.start(true, true);
		queue.grantQueuePrivilege("ALL", username);

		String test_data = "new message";
		byte[] b_array;

		/* Enqueue */
		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		/* Dequeue */
		AQDequeueOption deq_option = new AQDequeueOption();
		message = queue.dequeue(deq_option);
		raw_payload = message.getRawPayload();
		b_array = raw_payload.getBytes();
		db_conn.commit();
		System.out.println("Successful enqueueAndDequeue");
	}

	public void multiConsumerQueue(AQSession aq_sess) throws AQException {

		AQAgent subs111, subs222;

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();

		qtable_prop.setMultiConsumer(true);

		AQQueueTable q_table = aq_sess.createQueueTable(username, constantName.aq_multiConsumerTable, qtable_prop);

		AQQueue queue = aq_sess.createQueue(q_table, constantName.aq_multiConsumerQueue, queue_prop);
		queue.start();

		/* Add subscribers to this queue: */
		subs111 = new AQAgent("GREEN_MULTI", null, 0);
		subs222 = new AQAgent("BLUE_MULTI", null, 0);

		queue.addSubscriber(subs111, null); /* no rule */
		queue.addSubscriber(subs222, "priority < 2"); /* with rule */
		System.out.println("Successful multiConsumerQueue");
	}

	public void enqueueMultiConsumer(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		AQQueue queue = aq_sess.getQueue(username, constantName.aq_multiConsumerQueue);

		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		System.out.println("Successful enqueueMultiConsumer");
	}

	public void dequeueMultiConsumer(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();
		AQQueue queue = aq_sess.getQueue(username, constantName.aq_multiConsumerQueue);

		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		AQDequeueOption deq_option = new AQDequeueOption();
		deq_option.setConsumerName("GREEN_MULTI");
		message = queue.dequeue(deq_option);
		raw_payload = message.getRawPayload();
		b_array = raw_payload.getBytes();
		db_conn.commit();

		System.out.println("Successful dequeueMultiConsumer");
	}

	public void enqueueMultiConsumerWithPriority(AQSession aq_sess) throws AQException, SQLException {

		String test_data;
		byte[] b_array;
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		AQQueue queue = aq_sess.getQueue(username, constantName.aq_multiConsumerQueue);

		for (int i = 0; i < 5; i++) {
			AQMessage message = queue.createMessage();

			test_data = "Small_message_" + (i + 1); /* some test data */
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
			queue.enqueue(enq_option, message);
		}
		db_conn.commit();
		System.out.println("Successful enqueueMultiConsumerWithPriority");
	}

	public void dequeueMultiConsumerBrowseMode(AQSession aq_sess) throws AQException, SQLException {

		String test_data = "new message";
		byte[] b_array;

		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		AQQueue queue = aq_sess.getQueue(username, constantName.aq_multiConsumerQueue);

		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		AQDequeueOption deq_option = new AQDequeueOption();
		deq_option.setConsumerName("GREEN_MULTI");
		deq_option.setDequeueMode(AQDequeueOption.DEQUEUE_BROWSE);
		deq_option.setWaitTime(10);
		message = queue.dequeue(deq_option);
		raw_payload = message.getRawPayload();
		b_array = raw_payload.getBytes();

		String ret_value = new String(b_array);
		System.out.println("Dequeued message: " + ret_value);
		db_conn.commit();
		System.out.println("Successful dequeueMultiConsumerBrowseMode");

	}

	public Map<Integer, String> pubSubAQ()
			throws AQException, JMSException, SQLException, JsonProcessingException, ClassNotFoundException {
		Map<Integer, String> response = new HashMap();

		TopicSession session = configData.topicDataSourceConnection();
		response.put(1, "Topic Connection created.");

		Topic topic = pubSubUtil.setupTopic(session, constantName.aq_pubSubTable, constantName.aq_pubSubQueue);
		response.put(2, "Topic created: " + topic.getTopicName());

		pubSubUtil.pubSub(session, constantName.aq_pubSubSubscriber1, topic.getTopicName(), "Sample text message");
		response.put(3, "Topic pubSub  executed.");

		AQQueueTable qtable= ((AQjmsSession) session).getQueueTable(username, constantName.aq_pubSubTable );
        qtable.drop(true);
		response.put(4, "Topic pubSub cleanup executed.");
	
        return response;
	}
	
	public void cleanupAQ(AQSession session, String queueTable) throws SQLException, JMSException, AQException {
		AQQueueTable qtable= session.getQueueTable(username, queueTable );
        qtable.drop(true);
	}
}
