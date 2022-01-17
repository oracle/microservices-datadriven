/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * 04/20/2020: This file is modified to support Kafka Java Client compatability to Oracle Transactional Event Queues.
 *
 */

package org.oracle.okafka.common;

import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.common.config.AbstractConfig;
import org.oracle.okafka.common.utils.Utils;


import java.net.InetSocketAddress;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public final class Cluster {

   //private volatile Connection jdbcConn = null;
   private final AbstractConfig configs;
   private final boolean isBootstrapConfigured;
   private final List<Node> nodes;
   private final Set<String> unauthorizedTopics;
   private final Set<String> internalTopics;
   private final Node controller;
   private final Map<TopicPartition, PartitionInfo> partitionsByTopicPartition;
   private final Map<String, List<PartitionInfo>> partitionsByTopic;
   private final Map<String, List<PartitionInfo>> availablePartitionsByTopic;
   private final Map<Node, List<PartitionInfo>> partitionsByNode;
   private final Map<Integer, Node> nodesById;
   private final ClusterResource clusterResource;

   public Cluster(String clusterId,
                  Collection<Node> nodes,
                  Collection<PartitionInfo> partitions,
                  Set<String> unauthorizedTopics,
                  Set<String> internalTopics, AbstractConfig configs) {
	   this(clusterId, false, nodes, partitions, unauthorizedTopics, internalTopics, null, configs);
   }

   
   public Cluster(String clusterId,
           Collection<Node> nodes,
           Collection<PartitionInfo> partitions,
           Set<String> unauthorizedTopics,
           Set<String> internalTopics,
           Node controller, AbstractConfig configs) {
	   this(clusterId, false, nodes, partitions, unauthorizedTopics, internalTopics, controller, configs);
}


   public Cluster(String clusterId,
		          boolean isBootstrapConfigured,
                  Collection<Node> nodes,
                  Collection<PartitionInfo> partitions,
                  Set<String> unauthorizedTopics,
                  Set<String> internalTopics,
                  Node controller,
                  AbstractConfig configs) {
	   this.configs = configs;
	   this.isBootstrapConfigured = isBootstrapConfigured;
       this.clusterResource = new ClusterResource(clusterId);
       // make a randomized, unmodifiable copy of the nodes
       List<Node> copy = new ArrayList<>(nodes);
       Collections.shuffle(copy);
       this.nodes = Collections.synchronizedList(copy);
       this.nodesById = new HashMap<>();
       for (Node node : nodes)
           this.nodesById.put(node.id(), node);
       
       // index the partitions by topic/partition for quick lookup
       this.partitionsByTopicPartition = new HashMap<>(partitions.size());
       for (PartitionInfo p : partitions)
           this.partitionsByTopicPartition.put(new TopicPartition(p.topic(), p.partition()), p);

       // index the partitions by topic and node respectively, and make the lists
       // unmodifiable so we can hand them out in user-facing apis without risk
       // of the client modifying the contents
       HashMap<String, List<PartitionInfo>> partsForTopic = new HashMap<>();
       HashMap<Node, List<PartitionInfo>> partsForNode = new HashMap<>();
       for (Node node : this.nodes) {
           partsForNode.put(node, new ArrayList<PartitionInfo>());
       }
       for (PartitionInfo p : partitions) {
           if (!partsForTopic.containsKey(p.topic()))
               partsForTopic.put(p.topic(), new ArrayList<PartitionInfo>());
           List<PartitionInfo> psTopic = partsForTopic.get(p.topic());
           psTopic.add(p);

           if (p.leader() != null) {
               List<PartitionInfo> psNode = Utils.notNull(partsForNode.get(p.leader()));
               psNode.add(p);
           }
       }
       this.partitionsByTopic = new HashMap<>(partsForTopic.size());
       this.availablePartitionsByTopic = new HashMap<>(partsForTopic.size());
       for (Map.Entry<String, List<PartitionInfo>> entry : partsForTopic.entrySet()) {
           String topic = entry.getKey();
           List<PartitionInfo> partitionList = entry.getValue();
           this.partitionsByTopic.put(topic, Collections.unmodifiableList(partitionList));
           List<PartitionInfo> availablePartitions = new ArrayList<>();
           for (PartitionInfo part : partitionList) {
               if (part.leader() != null)
                   availablePartitions.add(part);
           }
           this.availablePartitionsByTopic.put(topic, Collections.synchronizedList(availablePartitions));
       }
       this.partitionsByNode = new HashMap<>(partsForNode.size());
       for (Map.Entry<Node, List<PartitionInfo>> entry : partsForNode.entrySet())
           this.partitionsByNode.put(entry.getKey(), Collections.synchronizedList(entry.getValue()));
       
       this.unauthorizedTopics = Collections.synchronizedSet(unauthorizedTopics);
       this.internalTopics = Collections.synchronizedSet(internalTopics);
       this.controller = controller;
   }

  /* private synchronized Connection getConnection() {
	  if(jdbcConn != null) return jdbcConn;
	    
	  final List<String> nodeList = configs.getList(CommonClientConfigs.BOOTSTRAP_SERVERS_CONFIG);

	  for(int i=0; i < nodeList.size(); i++) {
		  String[] node1 = nodeList.get(i).trim().split(":");
		  if(node1.length != 2)
			  throw new ConfigException("Invalid node details:" + nodeList);
		  String host = node1[0].trim();
		  String port = node1[1].trim();	
		  StringBuilder urlBuilder =new StringBuilder("jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=" + port +")(HOST=" + host +"))");
		  urlBuilder.append("(CONNECT_DATA=");
		  if(!(configs.getString(CommonClientConfigs.ORACLE_SERVICE_NAME ).isEmpty()) ) {
			  //Integer nodeid = configs.getInt(CommonClientConfigs.ORACLE_INSTANCE_ID);
			  urlBuilder.append("(SERVICE_NAME=" + configs.getString(CommonClientConfigs.ORACLE_SERVICE_NAME)  +")");
					  //(((nodeid == 0) || (nodeid == ConfigDef.NO_DEFAULT_VALUE)) ? "" : ("_i" + Integer.toString(nodeid) + ".regress.rdbms.dev.us.oracle.com"))+")");  
		  } else {
			  urlBuilder.append("(SID=" + configs.getString(CommonClientConfigs.ORACLE_SID) + ")");
		  }
		  urlBuilder.append("))");
		  try {
			  OracleDataSource s=new OracleDataSource();
			  s.setURL(urlBuilder.toString());
		      jdbcConn = s.getConnection(configs.getString(CommonClientConfigs.ORACLE_USER_NAME), configs.getString(CommonClientConfigs.ORACLE_PASSWORD));
		      break;
		  }
		  catch (SQLException sql) {
			  if(i == nodeList.size()-1) {
				  jdbcConn = null;
				  throw new KafkaException("unable to connect to node", sql);
			  }	
			  
		  }  
	  }
	 return jdbcConn;
   }
   
   public  synchronized  int getPartitions(String topic) {
	   if(topic == null) return 0;
	   if(jdbcConn == null) 
		 jdbcConn = getConnection();
	   String query = "begin dbms_aqadm.get_queue_parameter(?,?,?); end;";
	   CallableStatement cStmt = null;
	   int part = 1;
	   try {
       cStmt = jdbcConn.prepareCall(query);
	   cStmt.setString(1, topic);
	   cStmt.setString(2, "SHARD_NUM");
	   cStmt.registerOutParameter(3, OracleTypes.NUMBER);
	   cStmt.execute();
	   part = cStmt.getInt(3);
	   cStmt.close();
	   }
	   catch(SQLException sql) {
		   throw new KafkaException("Failed to get number of partitions :", sql);
	   }
	   return part;
   }*/


   /**
    * Create an empty cluster node with no Nodes and no topic-partitions.
    */
   public static Cluster empty() {
       return new Cluster(null, new ArrayList<Node>(0), new ArrayList<PartitionInfo>(0), Collections.<String>emptySet(),
               Collections.<String>emptySet(), null);
   }

   /**
    * Create a "bootstrap" cluster using the given list of host/ports
    * @param addresses The addresses
    * @return A cluster for these hosts/ports
    */
   public static Cluster bootstrap(List<InetSocketAddress> addresses, AbstractConfig configs, String serviceName, String instanceName) {
       List<Node> nodes = new ArrayList<>();
       for (InetSocketAddress address : addresses) {
    	   if( serviceName != null)
    		   nodes.add(new Node(-1, address.getHostString(), address.getPort(), serviceName, instanceName));
    	   else
               nodes.add(new Node(-1, address.getHostString(), address.getPort(), configs.getString(CommonClientConfigs.ORACLE_SERVICE_NAME), configs.getString(CommonClientConfigs.ORACLE_INSTANCE_NAME)));
           break;
       }
       return new Cluster(null, true, nodes, new ArrayList<PartitionInfo>(0), Collections.<String>emptySet(), Collections.<String>emptySet(), null, configs);
   }

   /**
    * Return a copy of this cluster combined with `partitions`.
    */
   public Cluster withPartitions(Map<TopicPartition, PartitionInfo> partitions) {
       Map<TopicPartition, PartitionInfo> combinedPartitions = new HashMap<>(this.partitionsByTopicPartition);
       combinedPartitions.putAll(partitions);
       return new Cluster(clusterResource.clusterId(), this.nodes, combinedPartitions.values(),
               new HashSet<>(this.unauthorizedTopics), new HashSet<>(this.internalTopics), this.controller, null);
   }
   
   public AbstractConfig getConfigs() {
	   return this.configs;
   }
   /**
    * @return The known set of Nodes
    */
   public List<Node> nodes() {
       return this.nodes;
   }
   
   /**
    * Get the node by the node id (or null if no such node exists)
    * @param id The id of the node
    * @return The node, or null if no such node exists
    */
   public Node nodeById(int id) {
       return this.nodesById.get(id);
   }

   /**
    * Get the current leader for the given topic-partition
    * @param topicPartition The topic and partition we want to know the leader for
    * @return The Node that is the leader for this topic-partition, or null if there is currently no leader
    */
   public Node leaderFor(TopicPartition topicPartition) {
	  
	   PartitionInfo info = partitionsByTopicPartition.get(topicPartition);
       if (info == null)
           return null;
       else
           return info.leader();
   }
   
   public Node leader() {
	   return nodes.size()!=0 ? nodes.get(0) : null;
   }

   /**
    * Get the metadata for the specified partition
    * @param topicPartition The topic and partition to fetch info for
    * @return The metadata about the given topic and partition
    */
   public PartitionInfo partition(TopicPartition topicPartition) {
       return partitionsByTopicPartition.get(topicPartition);
   }

   /**
    * Get the list of partitions for this topic
    * @param topic The topic name
    * @return A list of partitions
    */
   public List<PartitionInfo> partitionsForTopic(String topic) {
       List<PartitionInfo> parts = this.partitionsByTopic.get(topic);
       return (parts == null) ? Collections.<PartitionInfo>emptyList() : parts;
   }

   /**
    * Get the number of partitions for the given topic
    * @param topic The topic to get the number of partitions for
    * @return The number of partitions or null if there is no corresponding metadata
    */
   public Integer partitionCountForTopic(String topic) {
       List<PartitionInfo> partitions = this.partitionsByTopic.get(topic);
       return partitions == null ? null : partitions.size();
   }
   /**
    * Get the list of available partitions for this topic
    * @param topic The topic name
    * @return A list of partitions
    */
   public List<PartitionInfo> availablePartitionsForTopic(String topic) {
       List<PartitionInfo> parts = this.availablePartitionsByTopic.get(topic);
       return (parts == null) ? Collections.<PartitionInfo>emptyList() : parts;
   }

   /**
    * Get the list of partitions whose leader is this Node
    * @param node The Node
    * @return A list of partitions
    */
   public List<PartitionInfo> partitionsForNode(Node node) {
       List<PartitionInfo> parts = this.partitionsByNode.get(node);
       return (parts == null) ? Collections.<PartitionInfo>emptyList() : parts;
   }

    /**
    * Get all topics.
    * @return a set of all topics
    */
   public Set<String> topics() {
       return this.partitionsByTopic.keySet();
   }
   public Set<String> unauthorizedTopics() {
       return unauthorizedTopics;
   }

   public Set<String> internalTopics() {
       return internalTopics;
   }

   public boolean isBootstrapConfigured() {
       return isBootstrapConfigured;
   }

   public ClusterResource clusterResource() {
       return clusterResource;
   }

   public Node controller() {
       return leader();
   }

   @Override
   public String toString() {
       return "Cluster(id = " + clusterResource.clusterId() + ", nodes = " + this.nodes +
           ", partitions = " + this.partitionsByTopicPartition.values() + ", controller = " + controller + ")";
   }
   
   /*public void close() throws SQLException {
	   if(jdbcConn != null) {
		   jdbcConn.close();
	   }
   
   }*/
   
}
