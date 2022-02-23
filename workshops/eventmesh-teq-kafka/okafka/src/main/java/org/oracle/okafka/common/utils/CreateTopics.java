/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.utils;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import org.oracle.okafka.common.errors.InvalidConfigurationException;
import org.oracle.okafka.common.errors.InvalidTopicException;
import org.oracle.okafka.common.errors.TopicExistsException;
import org.oracle.okafka.common.requests.CreateTopicsRequest.TopicDetails;

public class CreateTopics {

	private static void setQueueParameter(Connection jdbcConn, String topic, String paraName, int paraValue) throws SQLException 
	{
		String qParaTxt = " begin sys.dbms_aqadm.set_queue_parameter(?, ?, ?); end;";
		CallableStatement qParaStmt = null;
		try {
		qParaStmt = jdbcConn.prepareCall(qParaTxt);
		qParaStmt.setString(1, Utils.enquote(topic));
		qParaStmt.setString(2, paraName);
		qParaStmt.setInt(3, paraValue);
		qParaStmt.execute(); 
		} catch(SQLException e) {
			throw e;
		}finally {
			if(qParaStmt != null) {
				try {
					qParaStmt.close();
				}catch(Exception e) {}
			}
		}
	}
	
	private static void startTopic(Connection jdbcConn, String topic) throws SQLException 
	{
		String sQTxt = "begin sys.dbms_aqadm.start_queue(?); end;";
		CallableStatement sQStmt = null;
		try {
		sQStmt = jdbcConn.prepareCall(sQTxt);
		sQStmt.setString(1, Utils.enquote(topic));
		sQStmt.execute(); 
		} catch(SQLException e) {
			throw e;
		}finally {
			if(sQStmt != null) {
				try {
					sQStmt.close();
				} catch(Exception e) {}
			 }
		}
	}

	private static void setPartitionNum(Connection jdbcConn, String topic, int numPartition) throws SQLException {
		setQueueParameter(jdbcConn, topic, "SHARD_NUM", numPartition);
	}
	private static void setKeyBasedEnqueue(Connection jdbcConn, String topic) throws SQLException {
		setQueueParameter(jdbcConn, topic, "KEY_BASED_ENQUEUE", 2);
	}
	private static void setStickyDeq(Connection jdbcConn, String topic) throws SQLException {
		setQueueParameter(jdbcConn, topic, "STICKY_DEQUEUE", 1);
	}
	
	public static Map<String, Exception> createTopics(Connection jdbcConn, Map<String, TopicDetails> topics) throws SQLException { 
		 CallableStatement cStmt = null;
		 Map<String, Exception> result = new HashMap<>();
		 try {		 
			 String topic;
			 TopicDetails details;
			 long retentionSec = 0l;
			 boolean retentionSet = false;
			 for(Map.Entry<String, TopicDetails> topicDetails : topics.entrySet()) {
				 topic = topicDetails.getKey().trim();
				 details = topicDetails.getValue();
				 try {
					 String query = "declare qprops  dbms_aqadm.QUEUE_PROPS_T; begin ";
					 for(Map.Entry<String, String> config : details.configs.entrySet()) {
						 String property = config.getKey().trim();
						 if(property.equals("retention.ms")) {
							 retentionSec = Long.parseLong(config.getValue().trim())/1000;
							 query =  query + "qprops.retention_time := ? ;";
							retentionSet = true;
						 }
						 else throw new InvalidConfigurationException("Invalid configuration: " + property + "provided for topic: " + topic);
					 }
					 query = query + "sys.dbms_aqadm.create_sharded_queue(queue_name=>?, multiple_consumers=>(case ? when 1 then true else false end), queue_properties => qprops); end;";
					 cStmt = jdbcConn.prepareCall(query);
					 int indx = 1;
					 if(retentionSet) {
						 cStmt.setLong(indx,retentionSec);
						 indx++;
					 }
					 cStmt.setString(indx++, Utils.enquote(topic));
					 cStmt.setInt(indx++, 1);
					 
					 cStmt.execute();
					 setPartitionNum(jdbcConn,topic,details.numPartitions);
					 setKeyBasedEnqueue(jdbcConn,topic);
					 setStickyDeq(jdbcConn,topic);
					 startTopic(jdbcConn,topic);

				 } catch(SQLException sqlEx) {
					 if ( sqlEx.getErrorCode() == 24019 || sqlEx.getErrorCode() == 44003 ) {
						 result.put(topic, new InvalidTopicException(sqlEx)); 
					 }
					 else if ( sqlEx.getErrorCode() == 24001 ) {
						 result.put(topic, new TopicExistsException("Topic already exists: ", sqlEx));
					 }
					 else result.put(topic, sqlEx);
				 } catch(Exception ex) {
					 result.put(topic, ex);
				 }
				 if(result.get(topic) == null) {
					 result.put(topic, null);
				 }
			 }
		 } finally {
			 try { 
				 if(cStmt != null)
					 cStmt.close();
			 } catch(Exception e) {
				 //do nothing
			 }
		 }
		 return result;
	}

}
