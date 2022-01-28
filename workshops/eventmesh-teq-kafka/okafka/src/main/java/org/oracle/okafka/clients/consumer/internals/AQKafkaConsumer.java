/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.clients.consumer.internals;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.sql.Types;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicSession;
import javax.jms.TopicSubscriber;

import oracle.jms.AQjmsBytesMessage;
import oracle.jms.AQjmsConnection;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsSession;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.consumer.ConsumerConfig;
import org.oracle.okafka.clients.consumer.OffsetAndMetadata;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.network.AQClient;
import org.oracle.okafka.common.protocol.ApiKeys;
import org.oracle.okafka.common.requests.CommitRequest;
import org.oracle.okafka.common.requests.CommitResponse;
import org.oracle.okafka.common.requests.FetchRequest;
import org.oracle.okafka.common.requests.FetchResponse;
import org.oracle.okafka.common.requests.OffsetResetRequest;
import org.oracle.okafka.common.requests.OffsetResetResponse;
import org.oracle.okafka.common.requests.SubscribeRequest;
import org.oracle.okafka.common.requests.SubscribeResponse;
import org.oracle.okafka.common.requests.UnsubscribeResponse;
import org.oracle.okafka.common.utils.ConnectionUtils;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.MessageIdConverter;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.common.utils.Utils;

/**
 * This class consumes messages from AQ 
 */
public final class AQKafkaConsumer extends AQClient{
	//private final Logger log ;
	//Holds TopicPublishers of each node. Each TopicPublisher can contain a connection to corresponding node, session associated with that connection and topic publishers associated with that session
	private final Map<Node, TopicConsumers> topicConsumersMap;
	private final ConsumerConfig configs;
	private final Time time;
	private  String msgIdFormat = "00";
	public AQKafkaConsumer(LogContext logContext, ConsumerConfig configs, Time time)
	{   
		super(logContext.logger(AQKafkaConsumer.class), configs);
		this.configs = configs;
		this.topicConsumersMap = new HashMap<Node, TopicConsumers>();
		this.time =time;
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
		if(key == ApiKeys.FETCH) 
			return receive(request);
		if(key == ApiKeys.COMMIT)
		return commit(request);
		if(key == ApiKeys.SUBSCRIBE)
			return subscribe(request);
		if(key == ApiKeys.OFFSETRESET)
			return seek(request);
		if(key == ApiKeys.UNSUBSCRIBE)
			return unsubscribe(request);
		return null;
		
	}
	
	/**
	 * Consumes messages in bulk from a given topic . Consumes or wait till either timeout occurs or max.poll.records condition is met
	 * @param node consume by establishing connection to this instance. 
	 * @param topic topic from which messages to be consumed
	 * @param timeoutMs wait for messages until this time expires
	 * @return
	 */
	public ClientResponse receive(ClientRequest request) {
		Node node =request.destination();
		FetchRequest.Builder builder = (FetchRequest.Builder)request.requestBuilder();
		FetchRequest fetchRequest = builder.build();
		String topic = fetchRequest.topic();
		long timeoutMs = fetchRequest.pollTimeout();
		try {
			if(!topicConsumersMap.containsKey(node) ) {
				topicConsumersMap.put(node, new TopicConsumers(node));
			}
			Message[] messages = null;
			TopicConsumers consumers = topicConsumersMap.get(node);
			TopicSubscriber subscriber = consumers.getTopicSubscriber(topic);
			messages = ((AQjmsConsumer)subscriber).bulkReceive(configs.getInt(ConsumerConfig.MAX_POLL_RECORDS_CONFIG), timeoutMs);
			if(messages == null) 
				return createFetchResponse(request, topic, Collections.emptyList(), false);
			List<AQjmsBytesMessage> msgs = new ArrayList<>();
			
			for(int i=0; i < messages.length;i++) {
				if(messages[i] instanceof AQjmsBytesMessage)
					msgs.add((AQjmsBytesMessage)messages[i]);	
				else {
					try {
						int partition = messages[i].getIntProperty("partition");
						
						long offset = MessageIdConverter.getOffset(messages[i].getJMSMessageID());
						log.error("Message is not an instance of AQjmsBytesMessage: Topic {} partition {} offset{}",topic, partition, offset );
					} catch(JMSException exception) {
						//do nothing
						
					}
					
				}
			}
					
			return createFetchResponse(request, topic, msgs, false);
		} catch(JMSException exception) { 
 			if(!exception.getErrorCode().equals("120")) {
 				close(node);
				log.error("failed to receive messages from topic: {}", topic);
			}
			return createFetchResponse(request, topic, Collections.emptyList(), true);
		} catch(Exception ex) {
			close(node);
			return createFetchResponse(request, topic, Collections.emptyList(), true);
		}
	}
	
	private ClientResponse createFetchResponse(ClientRequest request, String topic, List<AQjmsBytesMessage> messages, boolean disconnected) {
		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
                request.createdTimeMs(), time.milliseconds(), disconnected, 
                new FetchResponse(topic, messages));
	}
	
	/**
	 * Commit messages consumed by all sessions.
	 */
	public ClientResponse commit(ClientRequest request) {
		CommitRequest.Builder builder = (CommitRequest.Builder)request.requestBuilder();
		CommitRequest commitRequest = builder.build();
		Map<Node, List<TopicPartition>> nodes =  commitRequest.nodes();
		Map<TopicPartition, OffsetAndMetadata> offsets = commitRequest.offsets();
		Map<Node, Exception> result = new HashMap<>();
		boolean error = false;
		for(Map.Entry<Node, List<TopicPartition>> node : nodes.entrySet()) {
			
			if(node.getValue().size() > 0) {
				TopicConsumers consumers = topicConsumersMap.get(node.getKey());
				try {
					
					consumers.getSession().commit();
					result.put(node.getKey(), null);
				
				} catch(JMSException exception) {
					error = true;
					result.put(node.getKey(), exception);
				}
			}
			
		}

		return createCommitResponse(request, nodes, offsets, result, error);
		
		
	}
	
	private ClientResponse createCommitResponse(ClientRequest request, Map<Node, List<TopicPartition>> nodes,
			Map<TopicPartition, OffsetAndMetadata> offsets, Map<Node, Exception> result, boolean error) {
		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
                request.createdTimeMs(), time.milliseconds(), false, 
                new CommitResponse(result, nodes, offsets, error));
	}
	
	private String getMsgIdFormat(Connection con, String topic )
	{
		String msgFormat = "66";
		
		PreparedStatement msgFrmtStmt = null;
		ResultSet rs = null;
		try{
			String enqoteTopic = Utils.enquote(topic);
			String msgFrmtTxt = "select msgid from "+enqoteTopic+" where rownum = ?";
			msgFrmtStmt = con.prepareStatement(msgFrmtTxt);
			msgFrmtStmt.setInt(1,1);
			rs = msgFrmtStmt.executeQuery();
			if(rs.next() ) {
				msgFormat = rs.getString(1).substring(26, 28);
			}
		}catch(Exception e) {
			//Do Nothing
		}
		finally {
			try { 
				if(msgFrmtStmt != null) {msgFrmtStmt.close();}
   			} catch(Exception e) {}
   		}
		return msgFormat;

	}
	
	private class SeekInput {
    	static final int SEEK_BEGIN = 1;
    	static final int SEEK_END = 2;
    	static final int SEEK_MSGID = 3;
    	static final int NO_DISCARD_SKIPPED = 1;
    	static final int DISCARD_SKIPPED = 2;
    	int partition;
    	int priority;
    	int seekType;
    	String seekMsgId;
    	public SeekInput() {
    		priority = 1;
    	}
    }
    

private static void validateMsgId(String msgId) throws IllegalArgumentException {
    
      if(msgId == null || msgId.length() !=32)
        throw new IllegalArgumentException("Invalid Message Id " + ((msgId==null)?"null":msgId));
    
      try {
        for(int i =0; i< 32 ; i+=4)
        {
          String msgIdPart = msgId.substring(i,i+4); 
          Long.parseLong(msgIdPart,16);
       }
      }catch(Exception e) {
        throw new IllegalArgumentException("Invalid Mesage Id " + msgId);
      }   
    }   
    /*private static int getpriority(String msgId) {
    	try {
    		
    	}catch(Exception e) {
    		return 1;
    	}
    }*/
	
	public ClientResponse seek(ClientRequest request) {
		Map<TopicPartition, Exception> responses = new HashMap<>();
		CallableStatement seekStmt = null;
		try {
			OffsetResetRequest.Builder builder = (OffsetResetRequest.Builder)request.requestBuilder();
			OffsetResetRequest offsetResetRequest = builder.build();
			Node node = request.destination();
			Map<TopicPartition, Long> offsetResetTimestamps = offsetResetRequest.offsetResetTimestamps();
			Map<String, Map<TopicPartition, Long>> offsetResetTimeStampByTopic = new HashMap<String, Map<TopicPartition, Long>>() ;
			for(Map.Entry<TopicPartition, Long> offsetResetTimestamp : offsetResetTimestamps.entrySet()) {
				String topic = offsetResetTimestamp.getKey().topic();
				if ( !offsetResetTimeStampByTopic.containsKey(topic) ) {
					offsetResetTimeStampByTopic.put(topic, new  HashMap<TopicPartition, Long>());
				}
				 offsetResetTimeStampByTopic.get(topic).put(offsetResetTimestamp.getKey(), offsetResetTimestamp.getValue());
			}
			TopicConsumers consumers = topicConsumersMap.get(node);
			Connection con = ((AQjmsSession)consumers.getSession()).getDBConnection();
			
			
			SeekInput[] seekInputs = null;
			String[] inArgs = new String[5];
			for(Map.Entry<String, Map<TopicPartition, Long>> offsetResetTimestampOfTopic : offsetResetTimeStampByTopic.entrySet()) {
				String topic =  offsetResetTimestampOfTopic.getKey();
				inArgs[0] = "Topic: " + topic + " ";
				try {
						if(msgIdFormat.equals("00") ) {
							msgIdFormat = getMsgIdFormat(con, topic);
						}

					int inputSize = offsetResetTimestampOfTopic.getValue().entrySet().size(); 
					seekInputs = new SeekInput[inputSize];
					int indx =0;
					for(Map.Entry<TopicPartition, Long> offsets : offsetResetTimestampOfTopic.getValue().entrySet()) {
						seekInputs[indx] = new SeekInput(); 
						try {
							TopicPartition tp = offsets.getKey();
							seekInputs[indx].partition = tp.partition();
							inArgs[1] = "Partrition: " + seekInputs[indx].partition;
							if(offsets.getValue() == -2L) {
								seekInputs[indx].seekType = SeekInput.SEEK_BEGIN; // Seek to Beginning
								inArgs[2]= "Seek Type: " + seekInputs[indx].seekType;
							}
							else if( offsets.getValue() == -1L) {
								seekInputs[indx].seekType = SeekInput.SEEK_END; // Seek to End
								inArgs[2]= "Seek Type: " + seekInputs[indx].seekType;
							}
							else {
								seekInputs[indx].seekType = SeekInput.SEEK_MSGID; // Seek to MessageId
								inArgs[2]= "Seek Type: " + seekInputs[indx].seekType;
								inArgs[3] ="Seek to Offset: " +  offsets.getValue();
								seekInputs[indx].seekMsgId = MessageIdConverter.getMsgId(tp, offsets.getValue(), msgIdFormat);
								inArgs[4] = "Seek To MsgId: "+seekInputs[indx].seekMsgId ;
								validateMsgId(seekInputs[indx].seekMsgId);
							}
						}catch(IllegalArgumentException e ) {
							String errorMsg = "";
							for(int i =0; i<inArgs.length; i++ ) {
								if(inArgs[i] == null)
									break;
								
								errorMsg += inArgs[i];
							}
							Exception newE  =  new IllegalArgumentException(errorMsg, e);
							throw newE;
						}
					}
					
					StringBuilder sb = new StringBuilder();
					sb.append("declare \n seek_output_array  dbms_aq.seek_output_array_t; \n ");
					sb.append("begin \n dbms_aq.seek(queue_name => ?,");	
					sb.append("consumer_name=>?,");
					sb.append("seek_input_array =>  dbms_aq.seek_input_array_t( ") ;
				    for(int i = 0; i < seekInputs.length; i++) {
				    	sb.append("dbms_aq.seek_input_t( shard=> ?, priority => ?, seek_type => ?, seek_pos => dbms_aq.seek_pos_t( msgid => hextoraw(?))) ");
				    	if(i != seekInputs.length-1)
				    		sb.append(", ");
				     }
					sb.append("), ");
					sb.append("skip_option => ?, seek_output_array => seek_output_array);\n");
					sb.append("end;\n" );
					seekStmt = con.prepareCall(sb.toString());
					int stmtIndx = 1;
					seekStmt.setString(stmtIndx++, Utils.enquote(topic));
					seekStmt.setString(stmtIndx++, configs.getString(ConsumerConfig.GROUP_ID_CONFIG));
					
					for(int i=0; i < seekInputs.length; i++) {
						seekStmt.setInt(stmtIndx++, seekInputs[i].partition);
						seekStmt.setInt(stmtIndx++, seekInputs[i].priority);
						seekStmt.setInt(stmtIndx++, seekInputs[i].seekType);
						if(seekInputs[i].seekType == SeekInput.SEEK_MSGID){
							seekStmt.setString(stmtIndx++, seekInputs[i].seekMsgId);
						}else {
							seekStmt.setNull(stmtIndx++,Types.CHAR);
						}
					}
					seekStmt.setInt(stmtIndx++, SeekInput.DISCARD_SKIPPED);
					seekStmt.execute();
			
				} catch(Exception e) {
					for(Map.Entry<TopicPartition, Long> offsets : offsetResetTimestampOfTopic.getValue().entrySet()) {
						responses.put(offsets.getKey(), e);
					}
			    }finally {
			    	if(seekStmt != null) {
			    		try { 
			    			seekStmt.close();
			    			seekStmt = null;
			    		}catch(Exception e) {}
			    	}
			    }
			}// While Topics
		
		} catch(Exception e) {
			return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
	                request.createdTimeMs(), time.milliseconds(), true, new OffsetResetResponse(responses, e));
		}
		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
                request.createdTimeMs(), time.milliseconds(), false, new OffsetResetResponse(responses, null));
	}
	
	private ClientResponse unsubscribe(ClientRequest request) {
		HashMap<String, Exception> response = new HashMap<>();
		for(Map.Entry<Node, TopicConsumers> topicConsumersByNode: topicConsumersMap.entrySet())
		{
			for(Map.Entry<String, TopicSubscriber> topicSubscriber : topicConsumersByNode.getValue().getTopicSubscriberMap().entrySet()) {
				try {
					((AQjmsConsumer)topicSubscriber.getValue()).close();
					response.put(topicSubscriber.getKey(), null);
					topicConsumersByNode.getValue().remove(topicSubscriber.getKey());
				}catch(JMSException jms) {
					 response.put(topicSubscriber.getKey(), jms);
				}
			}
			
			try {
				((AQjmsSession)topicConsumersByNode.getValue().getSession()).close();
				topicConsumersByNode.getValue().setSession(null);
			} catch(JMSException jms) {
				//log.error("Failed to close session: {} associated with connection: {} and node: {}  ", consumers.getSession(), consumers.getConnection(), node );
			}
		}
		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
                request.createdTimeMs(), time.milliseconds(), false, new UnsubscribeResponse(response));

	}
	
	public void connect(Node node) throws JMSException{
		//TODO CLEAN DEBUG
		log.debug("Start try Connect!");

		if(!topicConsumersMap.containsKey(node)) {
			TopicConsumers nodeConsumers = null;
			try {
				nodeConsumers = new TopicConsumers(node);
				//TODO CLEAN DEBUG
				log.debug("TopicConsumers Created!");


				topicConsumersMap.put(node, nodeConsumers);
			} catch(JMSException e) {
				e.printStackTrace();
				close(node, nodeConsumers);
				throw e;
			}
			
       	
        }
	}
	
	public boolean isChannelReady(Node node) {
		return topicConsumersMap.containsKey(node);
	}
	
	public void close(Node node) {
		if(topicConsumersMap.get(node) == null)
			return;
		close(node, topicConsumersMap.get(node));
		topicConsumersMap.remove(node);
	}
	
	/**
	 * Closes AQKafkaConsumer
	 */
	public void close() {
		log.trace("Closing AQ kafka consumer");
		for(Map.Entry<Node, TopicConsumers> nodeConsumers : topicConsumersMap.entrySet()) {
			close(nodeConsumers.getKey(), nodeConsumers.getValue());
		}
		log.trace("Closed AQ kafka consumer");
		topicConsumersMap.clear();
	}
		
	/**
	 * Closes connection, session associated with each connection  and all topic consumers associated with session.
	 */
	private void close(Node node, TopicConsumers consumers) {
		if(node == null || consumers == null)
			return;
		for(Map.Entry<String, TopicSubscriber> topicSubscriber : consumers.getTopicSubscriberMap().entrySet()) {
			try {
				((AQjmsConsumer)topicSubscriber.getValue()).close();
			}catch(JMSException jms) {
				log.error("Failed to close topic consumer for topic: {} ", topicSubscriber.getKey());
			}
		}
		try {
			((AQjmsSession)consumers.getSession()).close();
		} catch(JMSException jms) {
			log.error("Failed to close session: {} associated with connection: {} and node: {}  ", consumers.getSession(), consumers.getConnection(), node );
		}
		try {
			((AQjmsConnection)consumers.getConnection()).close();
		} catch(JMSException jms) {
			log.error("Failed to close connection: {} associated with node: {}  ", consumers.getConnection(), node );
		}
		topicConsumersMap.remove(node);
	}
	/**
	 * Creates topic connection to given node if connection doesn't exist.
	 * @param node to which connection has to be created.
	 * @throws JMSException throws jmsexception if failed to establish comnnection to given node.
	 */
	private void createTopicConnection(Node node) throws JMSException {
		createTopicConnection(node, TopicSession.AUTO_ACKNOWLEDGE);
		
	}
	private void createTopicConnection(Node node, int mode) throws JMSException {
		
		if(!topicConsumersMap.containsKey(node)) {
			TopicConsumers consumers =null;
			consumers = new TopicConsumers(node, mode);
			topicConsumersMap.put(node, consumers);
		}
		
	}
	
	public ClientResponse subscribe(ClientRequest request) {
		for(Map.Entry<Node, TopicConsumers> topicConsumersByNode: topicConsumersMap.entrySet())
		{
			for(Map.Entry<String, TopicSubscriber> topicSubscriber : topicConsumersByNode.getValue().getTopicSubscriberMap().entrySet()) {
				try {
					((AQjmsConsumer)topicSubscriber.getValue()).close();
					topicConsumersByNode.getValue().remove(topicSubscriber.getKey());
				}catch(JMSException jms) {
					 //do nothing
				}
			}
			
			try {
				((AQjmsSession)topicConsumersByNode.getValue().getSession()).close();
				topicConsumersByNode.getValue().setSession(null);
			} catch(JMSException jms) {
				//log.error("Failed to close session: {} associated with connection: {} and node: {}  ", consumers.getSession(), consumers.getConnection(), node );
			}
		}
		SubscribeRequest.Builder builder = (SubscribeRequest.Builder)request.requestBuilder();
		SubscribeRequest commitRequest = builder.build();
		String topic = commitRequest.getTopic();
		Node node = request.destination();
		try {
			if(!topicConsumersMap.containsKey(node) ) {
				topicConsumersMap.put(node, new TopicConsumers(node));
			}
			TopicConsumers consumers = topicConsumersMap.get(node);	
			consumers.getTopicSubscriber(topic);
		} catch(JMSException exception) {
			close(node);
			return createSubscribeResponse(request, topic, exception, false);
		}
		
		return createSubscribeResponse(request, topic, null, false);
		
	}
	
	private ClientResponse createSubscribeResponse(ClientRequest request, String topic, JMSException exception, boolean disconnected) {
		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
                request.createdTimeMs(), time.milliseconds(), disconnected, 
                new SubscribeResponse(topic, exception));
		
	}

	
	/**This class is used to create and manage connection to database instance.
	 * Also creates, manages session associated with each connection and topic consumers associated with each session
	 */
	private final class TopicConsumers {
		private TopicConnection conn = null;
		private TopicSession sess = null;
		private Map<String, TopicSubscriber> topicSubscribers = null;
		private final Node node ;
		public TopicConsumers(Node node) throws JMSException {
			this(node, TopicSession.AUTO_ACKNOWLEDGE);
		}
		public TopicConsumers(Node node,int mode) throws JMSException {
			this.node = node;
			conn = createTopicConnection(node);
        	sess = createTopicSession(mode);
        	topicSubscribers = new HashMap<>();
		}
		/**
		 * Creates topic connection to node
		 * @param node destination to which connection is needed
		 * @return established topic connection
		 * @throws JMSException
		 */
		public TopicConnection createTopicConnection(Node node) throws JMSException {
			if(conn == null)
			    conn = ConnectionUtils.createTopicConnection(node, configs);
			return conn;
		}
		
		public TopicSubscriber getTopicSubscriber(String topic) throws JMSException {
			TopicSubscriber subscriber = topicSubscribers.get(topic);
			if(subscriber == null)
				subscriber = createTopicSubscriber(topic);
			return subscriber;
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
			 sess= ConnectionUtils.createTopicSession(conn, mode, true);
			 conn.start();
			 return sess;
				
		}
		
		/**
		 * Creates topic consumer for given topic
		 */
		private TopicSubscriber createTopicSubscriber(String topic) throws JMSException {
			refresh(node);
			Topic dest = ((AQjmsSession)sess).getTopic(ConnectionUtils.getUsername(configs), topic); 
			TopicSubscriber subscriber = sess.createDurableSubscriber(dest, configs.getString(ConsumerConfig.GROUP_ID_CONFIG));
			topicSubscribers.put(topic, subscriber);
			return subscriber;
		}
		
		private void refresh(Node node) throws JMSException {
			conn = createTopicConnection(node);
        	sess = createTopicSession(TopicSession.AUTO_ACKNOWLEDGE);
		}
 		public TopicConnection getConnection() {
			return conn;
		}
		
		public TopicSession getSession() {
			return sess;
		}
		
		public Map<String, TopicSubscriber> getTopicSubscriberMap() {
			return topicSubscribers;
		}
		
		public void setSession(TopicSession sess) {
			this.sess = sess;
		}
		
		public void setConnection(TopicConnection conn) {
			this.conn = conn;
		}
		
		public void remove(String topic) {
			topicSubscribers.remove(topic);
		}
		
	}
	}
