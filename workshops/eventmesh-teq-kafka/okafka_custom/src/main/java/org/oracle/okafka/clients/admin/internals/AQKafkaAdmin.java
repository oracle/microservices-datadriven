/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.clients.admin.internals;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.admin.AdminClientConfig;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.ConnectionException;
import org.oracle.okafka.common.errors.InvalidLoginCredentialsException;
import org.oracle.okafka.common.network.AQClient;
import org.oracle.okafka.common.protocol.ApiKeys;
import org.oracle.okafka.common.requests.CreateTopicsRequest;
import org.oracle.okafka.common.requests.CreateTopicsResponse;
import org.oracle.okafka.common.requests.DeleteTopicsRequest;
import org.oracle.okafka.common.requests.DeleteTopicsResponse;
import org.oracle.okafka.common.requests.CreateTopicsRequest.TopicDetails;
import org.oracle.okafka.common.utils.ConnectionUtils;
import org.oracle.okafka.common.utils.CreateTopics;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.Time;

/**
 * AQ client for publishing requests to AQ and generating reponses.
 *
 */
public class AQKafkaAdmin extends AQClient{
	
	//private final Logger log;
	private final AdminClientConfig configs;
	private final Time time;
	private final Map<Node, Connection> connections;
	
	public AQKafkaAdmin(LogContext logContext, AdminClientConfig configs, Time time) {
		super(logContext.logger(AQKafkaAdmin.class), configs);
		this.configs = configs;
		this.time = time;
		this.connections = new HashMap<>();	
	}
	
	/**
	 * Send request to aq.
	 */
	@Override
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
		if(key == ApiKeys.CREATE_TOPICS) 
			return createTopics(request);
		if(key == ApiKeys.DELETE_TOPICS)
			return deleteTopics(request);
		if(key == ApiKeys.METADATA) 
			return getMetadata(request);
		return null;
		
	}
	
	/**
	 * Executes a series of queries on each entry in list of topics for creating a corresponding topic .
	 * @param request request for creating list of topics
	 * @return response for create topics request.
	 */
	private ClientResponse createTopics(ClientRequest request) {
		
		 Node node = request.destination();
		 CreateTopicsRequest.Builder builder= (CreateTopicsRequest.Builder)request.requestBuilder();
		 Map<String, TopicDetails> topics = builder.build().topics();
		 Connection jdbcConn = connections.get(node);		 
		 Map<String, Exception> result = new HashMap<>();
		 SQLException exception = null;
		 try {			 			 
			 result = CreateTopics.createTopics(jdbcConn, topics) ;
		 } catch(SQLException sql) {
			 exception = sql;
			 log.trace("Unexcepted error occured with connection to node {}, closing the connection", request.destination());
			 log.trace("Failed to create topics {}", topics.keySet());
			 try {
				 jdbcConn.close(); 
				 connections.remove(node);				 
				 log.trace("Connection with node {} is closed", request.destination());
			 } catch(SQLException sqlException) {
				 log.trace("Failed to close connection with node {}", request.destination());
			 }
		 } 
		 return createTopicsResponse(result, exception, exception != null, request);	 
	}
	
	@Override
	public boolean isChannelReady(Node node) {
		return connections.containsKey(node);
	}
	
	/**
	 * Generates a response for create topics request.
	 */
	private ClientResponse createTopicsResponse(Map<String, Exception> errors, Exception result, boolean disconnected, ClientRequest request) {
		CreateTopicsResponse topicResponse = new CreateTopicsResponse(errors);
		if(result != null)
			topicResponse.setResult(result);
		ClientResponse response = new ClientResponse(request.makeHeader(),
				request.callback(), request.destination(), request.createdTimeMs(),
				time.milliseconds(), disconnected, topicResponse);

		return response;
	}
	
	/**
	 * Executes a series of queries on each entry in list of topics for deleting a corresponding topic .
	 * @param request request for deleting list of topics
	 * @return response for delete topics request.
	 */
	private ClientResponse deleteTopics(ClientRequest request) {
		 Node node = request.destination();
		 DeleteTopicsRequest.Builder builder= (DeleteTopicsRequest.Builder)request.requestBuilder();
		 Set<String> topics = builder.build().topics();
		 Connection jdbcConn = connections.get(node);
		 String query = "begin dbms_aqadm.drop_sharded_queue(queue_name=>?, force =>(case ? when 1 then true else false end)); end;";
		 CallableStatement cStmt = null;
		 Map<String, SQLException> result = new HashMap<>();
		 Set<String> topicSet = new HashSet<>(topics);
		 try {			 
			 cStmt = jdbcConn.prepareCall(query);
			 for(String topic: topics) {
				 try {
					 cStmt.setString(1, topic);
					 cStmt.setInt(2, 1);
					 cStmt.execute();  
				 } catch(SQLException sql) {
					 log.trace("Failed to delete topic : {}", topic);
					 result.put(topic, sql);
				 }
				 if(result.get(topic) == null) {
					 topicSet.remove(topic);
					 log.trace("Deleted a topic : {}", topic);
					 result.put(topic, null);
				 }
				 
			 } 
		 } catch(SQLException sql) {
			 log.trace("Unexcepted error occured with connection to node {}, closing the connection", node);
			 log.trace("Failed to delete topics : {}", topicSet);
			 try {
				 connections.remove(node);
				 jdbcConn.close(); 
				 log.trace("Connection with node {} is closed", request.destination());
			 } catch(SQLException sqlException) {
				 log.trace("Failed to close connection with node {}", node);
			 }
			 return deleteTopicsResponse(result, sql,true, request);
		 }
		 try {
			 cStmt.close();
		 } catch(SQLException sql) {
			 //do nothing
		 }
		 return deleteTopicsResponse(result, null, false, request);
	}
	
	/**
	 * Generates a response for delete topics request.
	 */
	private ClientResponse deleteTopicsResponse(Map<String, SQLException> errors, Exception result, boolean disconnected, ClientRequest request) {
		DeleteTopicsResponse topicResponse = new DeleteTopicsResponse(errors);
		if(result != null)
			topicResponse.setResult(result);
		ClientResponse response = new ClientResponse(request.makeHeader(),
				request.callback(), request.destination(), request.createdTimeMs(),
				time.milliseconds(), disconnected, topicResponse);
		return response;
	}
	
	private ClientResponse getMetadata(ClientRequest request) {
		ClientResponse response = getMetadataNow(request, connections.get(request.destination()));
		if(response.wasDisconnected()) 
			connections.remove(request.destination());
		
		return response;
	}
	
	/**
	 * Creates a connection to given node if already doesn't exist
	 * @param node node to be connected 
	 * @return returns connection established
	 * @throws SQLException
	 */
	private Connection getConnection(Node node) {
		try {
			connections.put(node, ConnectionUtils.createJDBCConnection(node, configs));
		} catch(SQLException sqlException) {
			if(sqlException.getErrorCode()== 1017)
			throw new InvalidLoginCredentialsException(sqlException);
			throw new ConnectionException(sqlException.getMessage());
		}
		return connections.get(node);
	}
	
	@Override
	public void connect(Node node) {
		getConnection(node);
	}
	
	/**
	 * Closes all existing connections to a cluster.
	 */
	@Override
	public void close() {
		for(Map.Entry<Node, Connection> connection: connections.entrySet()) {
			close(connection.getKey());
		}
	}
	
	/**
	 * Close connection to a given node
	 */
	@Override
	public void close(Node node) {
		if(connections.containsKey(node)) {
			Connection conn = connections.get(node);
			try {
				conn.close();
				connections.remove(node);
				log.trace("Connection to node {} closed", node);
			} catch(SQLException sql) {
				
			}
			
		}
	}
		
	

}
