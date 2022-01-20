/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.clients.producer.internals;

import java.nio.ByteBuffer;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.jms.*;

import oracle.jms.AQjmsBytesMessage;
import oracle.jms.AQjmsException;
import oracle.jms.AQjmsProducer;
import oracle.jms.AQjmsSession;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.producer.ProducerConfig;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.errors.NotLeaderForPartitionException;
import org.oracle.okafka.common.header.Header;
import org.oracle.okafka.common.network.AQClient;
import org.oracle.okafka.common.protocol.ApiKeys;
import org.oracle.okafka.common.record.MemoryRecords;
import org.oracle.okafka.common.record.MutableRecordBatch;
import org.oracle.okafka.common.record.Record;
import org.oracle.okafka.common.utils.ConnectionUtils;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.Time;

/**
 * This class sends messages to AQ
 */
public final class AQKafkaProducer extends AQClient {
	
	//Holds TopicPublishers of each node. Each TopicPublisher can contain a connection to corresponding node, session associated with that connection and topic publishers associated with that session
	private final Map<Node, TopicPublishers> topicPublishersMap;
	private final ProducerConfig configs;
	private final Time time;
	public AQKafkaProducer(LogContext logContext, ProducerConfig configs, Time time)
	{   
		super(logContext.logger(AQKafkaProducer.class), configs);
		this.configs = configs;
		this.time = time;
		this.topicPublishersMap = new HashMap<Node, TopicPublishers>();
	}

	public void connect(Node node) throws JMSException {
		TopicPublishers nodePublishers = null;
		try {
		 nodePublishers = new TopicPublishers(node);
		 topicPublishersMap.put(node, nodePublishers);
		}catch(JMSException e) {
			close(node, nodePublishers);
			throw e;
		}	          	
	}
	
	public boolean isChannelReady(Node node) {
		if(topicPublishersMap.containsKey(node)) {
			return true;
		}
		return false;
	}
	
	public ClientResponse send(ClientRequest request) {
		return parseRequest(request, request.apiKey());	
	}
	
	/**
	 * Determines the type of request and calls appropriate method for handling request
	 * @param request request to be sent
	 * @param key uniquely identifies type of request.
	 * @return response for given request
	 */
	private ClientResponse parseRequest( ClientRequest request, ApiKeys key) {
		if(key == ApiKeys.PRODUCE) 
			return publish(request);
		if(key == ApiKeys.METADATA)
		return getMetadata(request);
		return null;
		
	}
	
	/**
	 *Unwraps memory records of a producer batch into records. 
	 *Then translates each record into AQjmsBytesMessage and sends them to database instance as AqjmsBytesMessage array.
	 *Returns response for all messages in a memory records.
	 */
	private ClientResponse publish(ClientRequest request) {
		ProduceRequest.Builder builder = (ProduceRequest.Builder)request.requestBuilder();
		ProduceRequest produceRequest = builder.build();
		Node node = request.destination();
		TopicPartition topicPartition = produceRequest.getTopicpartition();
		MemoryRecords memoryRecords = produceRequest.getMemoryRecords();
		TopicPublishers nodePublishers;
		AQjmsBytesMessage[] msgs =null;
		ProduceResponse.PartitionResponse partitionResponse = null;
		boolean disconnected = false;

		try {	
			nodePublishers = topicPublishersMap.get(node);
			TopicSession session = nodePublishers.getSession();

			final List<AQjmsBytesMessage> messages = new ArrayList<>();
			Iterator<MutableRecordBatch> mutableRecordBatchIterator = memoryRecords.batchIterator();
			while(mutableRecordBatchIterator.hasNext()) {
				Iterator<Record>  recordIterator = mutableRecordBatchIterator.next().iterator();
				while(recordIterator.hasNext()) {
					Record record = recordIterator.next();
					messages.add(createBytesMessage(session, topicPartition, record.key(), record.value(), record.headers()));
				}
			}

			TopicPublisher publisher = null;
			TopicPublishers publishers = topicPublishersMap.get(node);
			publisher = publishers.getTopicPublisher(topicPartition.topic());

			msgs = messages.toArray(new AQjmsBytesMessage[0]);

			sendToAQ(msgs, publisher);

		} catch(Exception exception) {
			exception.printStackTrace();

			partitionResponse =  createResponses(topicPartition, new NotLeaderForPartitionException(exception), msgs);
            if(exception instanceof AQjmsException) {
            	if (((AQjmsException)exception).getErrorNumber() == 25348 ) {
            		partitionResponse =  createResponses(topicPartition, new NotLeaderForPartitionException(exception), msgs);    
            	}
            } else { 	
            	log.trace("Unexcepted error occured with connection to node {}, closing the connection", node);
    			try {
    				 TopicConnection conn = topicPublishersMap.get(node).getConnection();
    				 topicPublishersMap.remove(node);
    				 conn.close();
    				 disconnected = true;
    				 log.trace("Connection with node {} is closed", request.destination()); 
    			 } catch(JMSException jmsException) {
    				 log.trace("Failed to close connection with node {}", node);
    			 }
    			
    			log.error("failed to send messages to topic : {} with partition: {}", topicPartition.topic(), topicPartition.partition());
    			partitionResponse =  createResponses(topicPartition, exception, msgs);			
            }
    	}
        if( partitionResponse == null)
        	partitionResponse = createResponses(topicPartition, null, msgs);	
		return createClientResponse(request, topicPartition, partitionResponse, disconnected);

	}
	
	private ClientResponse createClientResponse(ClientRequest request, TopicPartition topicPartition, ProduceResponse.PartitionResponse partitionResponse, boolean disconnected) {
		return  new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
				                   request.createdTimeMs(), time.milliseconds(), disconnected, 
				                   new ProduceResponse(topicPartition, partitionResponse));
	}
	
	/**
	 * Bulk send messages to AQ.
	 * @param messages array of AQjmsBytesmessage to be sent
	 * @param publisher topic publisher used for sending messages
	 * @throws JMSException throws JMSException
	 */
	private void sendToAQ(AQjmsBytesMessage[] messages, TopicPublisher publisher) throws JMSException {
		for (AQjmsBytesMessage message :  messages) {
			message.reset();
			log.debug("sendToAq :: message JMSMessageID {}", message.getJMSMessageID());
			log.debug("sendToAq :: message Body {}", message.getBodyLength());
		}
		//Sends messages in bulk using topic publisher
	    // ((AQjmsProducer)publisher).bulkSend(publisher.getTopic(), messages);
		try {
			((AQjmsProducer)publisher).bulkSend((Destination)publisher.getTopic(), messages);
		} catch (Exception ex) {
			ex.printStackTrace();
			throw ex;
		}
	}
	
	/**
	 * Creates AQjmsBytesMessage from ByteBuffer's key, value and headers
	 */
	private AQjmsBytesMessage createBytesMessage(TopicSession session, TopicPartition topicPartition, ByteBuffer key, ByteBuffer value, Header[] headers) throws JMSException {
		AQjmsBytesMessage msg=null;
	    msg = (AQjmsBytesMessage)(session.createBytesMessage());
	    byte[] keyByteArray  = new byte[key.limit()];
		key.get(keyByteArray);
	    byte[] payload = new byte[value.limit()];
	    value.get(payload);
	    msg.writeBytes(payload);
	    msg.setJMSCorrelationID(new String(keyByteArray));
	    payload = null;	
	    msg.setStringProperty("topic", topicPartition.topic());
	    msg.setStringProperty("AQINTERNAL_PARTITION", Integer.toString(topicPartition.partition()*2));
		return msg;
	}
	
	/**
	 * Creates response for records in a producer batch from each corresponding AQjmsBytesMessage data updated after send is done.
	 */
	private ProduceResponse.PartitionResponse createResponses(TopicPartition tp, Exception exception, AQjmsBytesMessage[] msgs) {
		int iter=0;
		//Map<TopicPartition, ProduceResponse.PartitionResponse> responses = new HashMap<>();
		ProduceResponse.PartitionResponse response =new ProduceResponse.PartitionResponse(exception);
		if(exception == null) {
			response.msgIds = new ArrayList<>();
			response.logAppendTime = new ArrayList<>();
			String msgId = null;
			long timeStamp = -1;
			while(iter<msgs.length) {
				try {
					msgId = msgs[iter].getJMSMessageID(); 
					timeStamp = msgs[iter].getJMSTimestamp();
					
				} catch(JMSException jmsException) {
					msgId = null;
					timeStamp = -1;
				}
				response.msgIds.add(msgId);
				response.logAppendTime.add(timeStamp);
				iter++;
			}
			}
		//responses.put(new TopicPartition(tp.topic(), tp.partition()), response);		
		return response;
	}
	
	private ClientResponse getMetadata(ClientRequest request) {
		Connection conn = null;
		try {
			conn = ((AQjmsSession)topicPublishersMap.get(request.destination()).getSession()).getDBConnection();			
		} catch(JMSException jms) {			
			try {
				log.trace("Unexcepted error occured with connection to node {}, closing the connection", request.destination());
				topicPublishersMap.get(request.destination()).getConnection().close();
				log.trace("Connection with node {} is closed", request.destination());
			} catch(JMSException jmsEx) {
				log.trace("Failed to close connection with node {}", request.destination());
			}
		}
		
		ClientResponse response = getMetadataNow(request, conn);
		if(response.wasDisconnected()) 
			topicPublishersMap.remove(request.destination());
		return response;
	}
	
	/**
	 * Closes AQKafkaProducer
	 */
	public void close() {
		for(Map.Entry<Node, TopicPublishers> nodePublishers : topicPublishersMap.entrySet()) {
			close(nodePublishers.getKey(), nodePublishers.getValue());
		}
		topicPublishersMap.clear();
	}
	
	public void close(Node node) {
		
	}
	
	/**
	 * Closes all connections, session associated with each connection  and all topic publishers associated with session.
	 */
	private void close(Node node, TopicPublishers publishers) {
		if( node == null || publishers == null)
			return ;
		for(Map.Entry<String, TopicPublisher> topicPublisher : publishers.getTopicPublisherMap().entrySet()) {
			try {
				topicPublisher.getValue().close();
			}catch(JMSException jms) {
				log.error("failed to close topic publisher for topic {} ", topicPublisher.getKey());
			}
		}
		try {
			publishers.getSession().close();
		} catch(JMSException jms) {
			log.error("failed to close session {} associated with connection {} and node {}  ",publishers.getSession(), publishers.getConnection(), node );
		}
		try {
			publishers.getConnection().close();
		} catch(JMSException jms) {
			log.error("failed to close connection {} associated with node {}  ",publishers.getConnection(), node );
		}
	}

	/**This class is used to create and manage connection to database instance.
	 * Also creates, manages session associated with each connection and topic publishers associated with each session
	 */
	private final class TopicPublishers {
		private TopicConnection conn;
		private TopicSession sess;
		private Map<String, TopicPublisher> topicPublishers = null;
		public TopicPublishers(Node node) throws JMSException {
			this(node, TopicSession.AUTO_ACKNOWLEDGE);
		}
		public TopicPublishers(Node node,int mode) throws JMSException {
			conn = createTopicConnection(node);
        	sess = createTopicSession(mode);
        	topicPublishers = new HashMap<>();
		}
		/**
		 * Creates topic connection to node
		 * @param node destination to which connection is needed
		 * @return established topic connection
		 * @throws JMSException
		 */
		public TopicConnection createTopicConnection(Node node) throws JMSException {
			conn = ConnectionUtils.createTopicConnection(node, configs);
			return conn;
		}
		
		public TopicPublisher getTopicPublisher(String topic) throws JMSException {
			TopicPublisher publisher = topicPublishers.get(topic);
			if(publisher == null)
				publisher = createTopicPublisher(topic);
			return publisher;
		}

		/**
		 * Creates topic session from established connection
		 * @param mode mode of acknowledgement with which session has to be created
		 * @return created topic session
		 * @throws JMSException
		 */
		public TopicSession createTopicSession(int mode) throws JMSException {		
			if(sess != null) 
				return sess;			
			 sess= ConnectionUtils.createTopicSession(conn, mode, false);
			 conn.start();
			 return sess;
				
		}
		
		/**
		 * Creates topic publisher for given topic
		 */
		private TopicPublisher createTopicPublisher(String topic) throws JMSException {
			// TODO New getOwner method to return Topic Owner based on App Configuration
			/* getOwner return the Topic Owner based on oracle.user.name property */
			String topic_owner = ConnectionUtils.getOwner(configs);

			// Topic dest = ((AQjmsSession)sess).getTopic(ConnectionUtils.getUsername(configs), topic);
			Topic dest = ((AQjmsSession)sess).getTopic(topic_owner, topic);
			TopicPublisher publisher = sess.createPublisher(dest);
			topicPublishers.put(topic, publisher);
			return publisher;
			
		}
		public TopicConnection getConnection() {
			return conn;
		}
		
		public TopicSession getSession() {
			return sess;
		}
		
		public Map<String, TopicPublisher> getTopicPublisherMap() {
			return topicPublishers;
		}
		
	}
	}
