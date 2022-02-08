/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.network;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLSyntaxErrorException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.PartitionInfo;
import org.oracle.okafka.common.config.AbstractConfig;
import org.oracle.okafka.common.requests.MetadataRequest;
import org.oracle.okafka.common.requests.MetadataResponse;
import org.oracle.okafka.common.requests.CreateTopicsRequest.TopicDetails;
import org.oracle.okafka.common.utils.CreateTopics;
import org.oracle.okafka.common.utils.Utils;
import org.slf4j.Logger;

import javax.jms.JMSException;
import oracle.jdbc.OracleTypes;

public abstract class AQClient {
	
	protected final Logger log ;
	private final AbstractConfig configs;
	public AQClient(Logger log, AbstractConfig configs) {
		this.log = log;
		this.configs = configs;
	}
	private Connection conn = null;
	public abstract ClientResponse send(ClientRequest request);
	
	public abstract boolean isChannelReady(Node node);
	
	public abstract void connect(Node node) throws JMSException;
	
	public abstract void close(Node node);
	
	public abstract void close();
	
	public ClientResponse getMetadataNow(ClientRequest request, Connection con) {
		MetadataRequest.Builder builder= (MetadataRequest.Builder)request.requestBuilder();
		MetadataRequest metadataRequest = builder.build();	
		List<Node> nodes = new ArrayList<>();
		List<PartitionInfo> partitionInfo = new ArrayList<>();
		Map<String, Exception> errorsPerTopic = new HashMap<>();
		List<String> metadataTopics = new ArrayList<String>(metadataRequest.topics());
		boolean disconnected = false;
		try { 
			getNodes(nodes, con); 
			if(nodes.size() == 0)
			  nodes.add(request.destination());
			if(nodes.size() > 0)					
			    getPartitionInfo(metadataRequest.topics(), metadataTopics, con, nodes, metadataRequest.allowAutoTopicCreation(), partitionInfo, errorsPerTopic);			
		} catch(Exception exception) { 
			if(exception instanceof SQLException) 
				if(((SQLException)exception).getErrorCode() == 6550) {
					log.error("execute on dbms_aqadm is not assigned", ((SQLException)exception).getMessage());
	        		log.info("create session, execute on dbms_aqin, dbms_aqadm , dbms_aqjms privileges required for producer or consumer to work");
				}
			if(exception instanceof SQLSyntaxErrorException)
				log.trace("Please grant select on gv_$instnce , gv_$listener_network, user_queues and user_queue_shards.");
			for(String topic : metadataTopics) {
				errorsPerTopic.put(topic, exception);
			}
			disconnected = true;			
			try {
				log.trace("Unexcepted error occured with connection to node {}, closing the connection", request.destination());
				con.close();
				log.trace("Connection with node {} is closed", request.destination());
			} catch(SQLException sqlEx) {
				log.trace("Failed to close connection with node {}", request.destination());
			}
				
				

       }
		return  new ClientResponse(request.makeHeader(),
				request.callback(), request.destination(), request.createdTimeMs(),
				System.currentTimeMillis(), disconnected, new MetadataResponse(nodes, partitionInfo, errorsPerTopic));
		
	}
	
	
	private void getNodes(List<Node> nodes, Connection con) throws SQLException {
		Statement stmt = null;
		try {
			stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
			String query = "select inst_id, instance_name from gv$instance";
			ResultSet result = stmt.executeQuery(query);
			Map<Integer, String> instances = new HashMap<>();
			while(result.next()) {
				instances.put(result.getInt(1), result.getString(2));
			}
			query = "select * from gv$listener_network";
			result = stmt.executeQuery(query);
			Map<Integer, String> services = new HashMap<>();
			while(result.next()) {
				if(result.getString(3).equalsIgnoreCase("SERVICE NAME")) {
					services.put(Integer.parseInt(result.getString(1)), result.getString(4));
				}
			}
			result.beforeFirst();
			while(result.next()) {
				if(result.getString(3).equalsIgnoreCase("LOCAL LISTENER") ) {
					try {
						String str = result.getString(4);

						StringBuilder sb = new StringBuilder();
						for(int ind = 0;ind < str.length(); ind++)
							if(str.charAt(ind) != ' ')
								sb.append(str.charAt(ind));
						str = sb.toString();
						String security = configs.getString(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG);
						if( (security.equalsIgnoreCase("PLAINTEXT") && getProperty(str, "PROTOCOL").equalsIgnoreCase("TCP"))  || (!security.equalsIgnoreCase("PLAINTEXT") && getProperty(str, "PROTOCOL").equalsIgnoreCase("TCPS")) ) {
							int id = Integer.parseInt(result.getString(1));
							if(services.get(id) != null) {
								String host = getProperty(str, "HOST");;
								Integer port = Integer.parseInt(getProperty(str, "PORT"));
								// TODO Review this code with team -- LOCAL HOST is being added.
								// Removing the add of the new node to avoid LOCAL HOST registration
								//nodes.add(new Node(id, host, port, services.get(id), instances.get(id)));
							}
						}
						/*
						StringTokenizer st = new StringTokenizer(str, "(");

						if(st.countTokens() == 4) {
							st.nextToken();
							String protocolStr = st.nextToken();
							if(protocolStr.substring(9, protocolStr.length()-1).equalsIgnoreCase("tcp")) {
								int id = Integer.parseInt(result.getString(1));
								if(services.get(id) != null) {
									String hostStr = st.nextToken();
									String host = hostStr.substring(5, hostStr.length()-1);
									String portStr = st.nextToken();
									Integer port = Integer.parseInt(portStr.substring(5, portStr.length()-2));									
									nodes.add(new Node(id, host, port, services.get(id), instances.get(id)));
								}							
							}
						}*/
						
					} catch(IndexOutOfBoundsException iob) {
						//do nothing
					}

				}
			}
			 /*List<InetSocketAddress> addresses = ClientUtils.parseAndValidateAddresses(configs.getList(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG));
			 InetSocketAddress address = addresses.get(0);
			 nodes.add(new Node(0, address.getHostString(), address.getPort(), configs.getString(CommonClientConfigs.ORACLE_SERVICE_NAME), configs.getString(CommonClientConfigs.ORACLE_INSTANCE_NAME)));*/
		} finally {
			try {
				if(stmt != null)
				stmt.close();
			} catch(SQLException sqlEx) {
				//do nothing
			}
		}
	}
	
private void getPartitionInfo(List<String> topics, List<String> topicsRem, Connection con, List<Node> nodes, boolean allowAutoTopicCreation, List<PartitionInfo> partitionInfo, Map<String, Exception> errorsPerTopic) throws Exception {
		
	if(nodes.size() <= 0 || topics == null || topics.isEmpty())
		return;
		
	String queryQShard = "select shard_id, enqueue_instance from user_queue_shards where  name = ? ";
	PreparedStatement stmt1 = null;
	try {
		stmt1 = con.prepareStatement(queryQShard);
		int node = 0 ;
		int nodesSize = nodes.size();
		ResultSet result1 = null;
		Node[] nodesArray = null;
		if(nodesSize > 1) {
			int max = -1;
			for(Node nodeNew : nodes) 
				if(nodeNew.id() > max)
					max = nodeNew.id();
			
			nodesArray = new Node[max];
			for(Node nodeNew : nodes) 
				nodesArray[nodeNew.id()-1] = nodeNew;
		}
		
		for(String topic : topics) {
			boolean topicDone = false;
			int partCnt = 0;
			try {
				//Get number of partitions
				partCnt = getPartitions(Utils.enquote(topic), con);
			} catch(SQLException sqlE) {
				int errorNo = sqlE.getErrorCode();
				if(errorNo == 24010)  {
					//Topic does not exist, it will be created
					continue;
				}
			}catch(Exception excp) {
				// Topic May or may not exists. We will not attempt to create it again
				topicsRem.remove(topic);
				continue;
			}
			
			boolean partArr[] =  new boolean[partCnt];
			for(int i =0; i<partCnt ;i++)
				partArr[i] = false;
			
			// If more than one RAC node then check who is owner Node for which partition
			if(nodes.size()  > 1) {
				
				stmt1.clearParameters();
				stmt1.setString(1, Utils.enquote(topic));
				result1 = stmt1.executeQuery();
				// If any row exist 
				if(result1.isBeforeFirst()) {
					while(result1.next() ) {
					int partNum = result1.getInt(1)/2;
					int nodeNum = result1.getInt(2);
					partitionInfo.add(new PartitionInfo(topic, partNum , nodesArray[nodeNum-1], null, null));	
					partArr[partNum] = true;
				 }
				 result1.close();
				 // For the partitions not yet mapped to an instance 
				 for(int i = 0; i < partCnt ; i++) {
					if( partArr[i] == false ) {
						partitionInfo.add(new PartitionInfo(topic, i , nodes.get(node++%nodesSize), null, null));	
					}
				 }
				 topicDone = true;
				} // Entry Existed in USER_QUEUE_SHARD
			}// Nodes > 1
		
			// No Record in USER_QUEUE_SHARD or Node =1 check if topic exist		   	
			if(!topicDone){ 
				for(int i = 0; i < partCnt ; i++) {
					partitionInfo.add(new PartitionInfo(topic, i , nodes.get(node++%nodesSize), null, null));
				}
				topicDone =true;
			}
			if(topicDone)
			  topicsRem.remove(topic);
			} // For all Topics
	
		if(allowAutoTopicCreation && topicsRem.size() > 0) {
			Map<String, TopicDetails> topicDetails = new HashMap<String, TopicDetails>();
			for(String topicRem : topicsRem) {
				topicDetails.put(topicRem, new TopicDetails(1, (short)0 , Collections.<String, String>emptyMap()));
			}
			Map<String, Exception> errors= CreateTopics.createTopics(con, topicDetails);
			for(String topicRem : topicsRem) {
				if(errors.get(topicRem) == null) {
		    		partitionInfo.add(new PartitionInfo(topicRem, 0, nodes.get(node++%nodesSize), null, null));
		    	} else {
		    		errorsPerTopic.put(topicRem, errors.get(topicRem));
		    	}
			}
		}
		} finally {
			try {
				if(stmt1 != null) 
					stmt1.close();		
			} catch(Exception ex) {
			//do nothing
			}
		}
	}

	private int getPartitions(String topic, Connection con) throws Exception {
		   if(topic == null) return 0;
		   String query = "begin dbms_aqadm.get_queue_parameter(?,?,?); end;";
		   CallableStatement cStmt = null;
		   int part = 1;
		   try {
	       cStmt = con.prepareCall(query);
	       cStmt.setString(1, topic);
		   cStmt.setString(2, "SHARD_NUM");
		   cStmt.registerOutParameter(3, OracleTypes.NUMBER);
		   cStmt.execute();
		   part = cStmt.getInt(3);
		   } 
		   catch(SQLException ex) {
			   throw ex;
		   }
		   finally {
			   try {
				   if(cStmt != null)
					   cStmt.close();
			   } catch(Exception ex) {
				   //Do Nothing
			   }
		   }		   
		   return part;
	   }  
	
	private String getProperty(String str, String property) {
		String tmp = str.toUpperCase();
		int index = tmp.indexOf(property.toUpperCase());
		if(index == -1)
			return null;
        int index1 = tmp.indexOf("=", index);
        if(index1 == -1)
        	return null;
        int index2 = tmp.indexOf(")", index1);
        if(index2 == -1)
        	return null;
        return str.substring(index1 + 1, index2).trim();
    }

}
