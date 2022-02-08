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

package org.oracle.okafka.clients.consumer.internals;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.jms.JMSException;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.KafkaClient;
import org.oracle.okafka.clients.Metadata;
import org.oracle.okafka.clients.RequestCompletionHandler;
import org.oracle.okafka.clients.consumer.OffsetAndMetadata;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.requests.CommitRequest;
import org.oracle.okafka.common.requests.CommitResponse;
import org.oracle.okafka.common.requests.FetchRequest;
import org.oracle.okafka.common.requests.FetchResponse;
import org.oracle.okafka.common.requests.OffsetResetRequest;
import org.oracle.okafka.common.requests.OffsetResetResponse;
import org.oracle.okafka.common.requests.SubscribeRequest;
import org.oracle.okafka.common.requests.SubscribeResponse;
import org.oracle.okafka.common.requests.UnsubscribeRequest;
import org.oracle.okafka.common.requests.UnsubscribeResponse;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.Time;
import org.slf4j.Logger;

import oracle.jms.AQjmsBytesMessage;

public class ConsumerNetworkClient {
	private static final int MAX_POLL_TIMEOUT_MS = 5000;
	private final Logger log;
	private final KafkaClient client;
    private final Metadata metadata;
    private final Time time;
    private final boolean autoCommitEnabled;
    private final int autoCommitIntervalMs;
    private long nextAutoCommitDeadline;
    private final long retryBackoffMs;
    private final int maxPollTimeoutMs;
    private final int requestTimeoutMs;
    private final int sesssionTimeoutMs;
    private final long defaultApiTimeoutMs;
    private final SubscriptionState subscriptions;
    private Set<String> subcriptionSnapshot;
    private final List<AQjmsBytesMessage> messages = new ArrayList<>();
	public ConsumerNetworkClient(LogContext logContext,
			KafkaClient client,
            Metadata metadata,
            SubscriptionState subscriptions,
            boolean autoCommitEnabled,
            int autoCommitIntervalMs,
            Time time,
            long retryBackoffMs,
            int requestTimeoutMs,
            int maxPollTimeoutMs,
            int sessionTimeoutMs,
            long defaultApiTimeoutMs) {
		this.log = logContext.logger(ConsumerNetworkClient.class);
        this.client = client;
        this.metadata = metadata;
        this.subscriptions = subscriptions;
        this.autoCommitEnabled = autoCommitEnabled;
        this.autoCommitIntervalMs = autoCommitIntervalMs;
        this.time = time;
        this.retryBackoffMs = retryBackoffMs;
        this.maxPollTimeoutMs = Math.min(maxPollTimeoutMs, MAX_POLL_TIMEOUT_MS);
        this.requestTimeoutMs = requestTimeoutMs;
        this.sesssionTimeoutMs = sessionTimeoutMs;
        //Snapshot of subscription. Useful for ensuring if all topics are subscribed.
        this.subcriptionSnapshot = new HashSet<>();
        this.defaultApiTimeoutMs = defaultApiTimeoutMs;
        
        if (autoCommitEnabled)
            this.nextAutoCommitDeadline = time.milliseconds() + autoCommitIntervalMs;
	}
	
	/**
	 * Poll from subscribed topics.
	 * Each node polls messages from a list of topic partitions for those it is a leader.
	 * @param timeoutMs poll messages for all subscribed topics.
	 * @return messages consumed.
	 */
	public List<AQjmsBytesMessage> poll(final long timeoutMs)  {
		this.messages.clear();
		Map<Node, String> pollMap = getPollableMap();
		long now = time.milliseconds();
		RequestCompletionHandler callback = new RequestCompletionHandler() {
			 public void onComplete(ClientResponse response) {
				 //do nothing;
			 }
		};
		for(Map.Entry<Node, String> poll : pollMap.entrySet()) {			 
			 Node node = poll.getKey();
			 if(!this.client.ready(node, now)) {
				 log.info("Failed to consume messages from node: {}", node);
			 } else {
				 ClientRequest request  = createFetchRequest(node, poll.getValue(), callback, requestTimeoutMs < timeoutMs ? requestTimeoutMs : (int)timeoutMs);
				 ClientResponse response = client.send(request, now);
				 handleResponse(response);
				 break;
			 }
			 
		}
		return this.messages;	
		
	}
	/**
	 * 
	 * @return map of <node , topic> . Every node is leader for its corresponding topic.
	 */
	private Map<Node, String> getPollableMap() {
		try {
			return Collections.singletonMap(metadata.fetch().leader(), this.subcriptionSnapshot.iterator().next());
		} catch(java.util.NoSuchElementException exception) {
			//do nothing
		}
		return Collections.emptyMap();
	}
	
	private ClientRequest createFetchRequest(Node destination, String topic, RequestCompletionHandler callback, int requestTimeoutMs) {
		return this.client.newClientRequest(destination,  new FetchRequest.Builder(topic, requestTimeoutMs) , time.milliseconds(), true, requestTimeoutMs, callback);
	}
	
	private void handleResponse(ClientResponse response) {
		if(response.wasDisconnected()) {
	    	client.disconnected(response.destination(), time.milliseconds());
	    	//metadata.requestUpdate();    	
	    }
		FetchResponse fetchResponse = (FetchResponse)response.responseBody();
		messages.addAll(fetchResponse.getMessages());
	}
	
	/**
	 * Subscribe to topic if not done
	 * @return true if subscription is successsful else false.
	 */
	public boolean mayBeTriggerSubcription(long timeout) {
		if(!subscriptions.subscription().equals(subcriptionSnapshot)) {
			String topic = getSubscribableTopics();
			long now = time.milliseconds();
			Node node = client.leastLoadedNode(now);

			if( node == null || !client.ready(node, now) ) {
				System.out.println("ATTENTION!!! ConsumerNetworkClient::Failed to subscribe to topic: + "+ topic);
				log.error("Failed to subscribe to topic: {}", topic);
				return false;
			}
			ClientRequest request = this.client.newClientRequest(node, new SubscribeRequest.Builder(topic), now, true, requestTimeoutMs < timeout ? requestTimeoutMs: (int)timeout, null);
	        ClientResponse response = this.client.send(request, now);
	        
			return handleSubscribeResponse(response);

		}
		return true;
		
	}
	
	private boolean handleSubscribeResponse(ClientResponse response) {
		if(response.wasDisconnected()) {
	    	client.disconnected(response.destination(), time.milliseconds());
	    	metadata.requestUpdate();
	    	
	    }
		SubscribeResponse subscribeResponse = (SubscribeResponse)response.responseBody();
		JMSException exception = subscribeResponse.getException();

		//TODO :  ConsumerNetworkClient::handleSubscribeResponse
		// At this point if user specify a wrong "group-id" the exception bellow is throwing but not shown to user.
		// oracle.jms.AQjmsException:
		// ORA-24047: invalid agent name string, agent name should be of the form NAME
		//     Cause: An invalid value was specified for the agent name parameter.
		//    Action: Specify a string of the form NAME. Then retry the operation.

		if(exception != null) { 
			log.error("failed to subscribe to topic {}", subscribeResponse.getTopic());		
			return false;
		}else {
			this.subcriptionSnapshot.add(subscribeResponse.getTopic());
		}
		return true;
		
	}
	
	/**
	 * Updates subscription snapshot and returns subscribed topic. 
	 * @return subscribed topic
	 */
	private String getSubscribableTopics() {
		//this.subcriptionSnapshot = new HashSet<>(subscriptions.subscription());
		return getSubscribedTopic();
	}
	/**
     * return subscribed topic.
	 */
	private String getSubscribedTopic() {
		HashSet<String> subscribableTopics = new HashSet<>();
		for(String topic : subscriptions.subscription()) {
			if(!this.subcriptionSnapshot.contains(topic)) {
				subscribableTopics.add(topic);
				this.subcriptionSnapshot.clear();
			}	
		}
		return subscribableTopics.iterator().next();
	}
	
	public boolean commitOffsetsSync(Map<TopicPartition, OffsetAndMetadata> offsets, long timeout) throws Exception{
		log.debug("Sending synchronous commit of offsets: {} request", offsets);
		
		long elapsed = 0;
		ClientRequest request;
		ClientResponse response;	
		request = this.client.newClientRequest(null, new CommitRequest.Builder(getCommitableNodes(offsets), offsets), time.milliseconds(), true);
		response = this.client.send(request, time.milliseconds());
		handleCommitResponse(response); 

		if(((CommitResponse)response.responseBody()).error()) {
			
			throw ((CommitResponse)response.responseBody()).getResult()
					                                       .entrySet().iterator().next().getValue();
		}
		
		return true;
	}
	
	private void handleCommitResponse(ClientResponse response) {
		CommitResponse commitResponse = (CommitResponse)response.responseBody();
		Map<Node, List<TopicPartition>> nodes =  commitResponse.getNodes();
		Map<TopicPartition, OffsetAndMetadata> offsets = commitResponse.offsets();
		Map<Node, Exception> result = commitResponse.getResult();
		for(Map.Entry<Node, Exception> nodeResult : result.entrySet()) {
			if(nodeResult.getValue() == null) {
				for(TopicPartition tp : nodes.get(nodeResult.getKey())) {
					log.debug("Commited to topic partiton: {} with  offset: {} ", tp, offsets.get(tp));
					offsets.remove(tp);
				}
				nodes.remove(nodeResult.getKey());	
			} else {
				for(TopicPartition tp : nodes.get(nodeResult.getKey())) {
					log.error("Failed to commit to topic partiton: {} with  offset: {} ", tp, offsets.get(tp));
				}
				
			}	
		}	
	}
	
	/**
	 * Returns nodes that have sessions ready for commit.
	 * @param offsets Recently consumed offset for each partition since last commit.
	 * @return map of node , list of partitions(node is leader for its corresponding partition list) that are ready for commit.
	 */
	private Map<Node, List<TopicPartition>> getCommitableNodes(Map<TopicPartition, OffsetAndMetadata> offsets) {
		Map<Node, List<TopicPartition>> nodes = new HashMap<>();
		Cluster cluster = metadata.fetch();
		for(Map.Entry<TopicPartition, OffsetAndMetadata> metadata : offsets.entrySet())	{
			if(!client.ready(cluster.leader(), time.milliseconds())) {
				log.error("Failed to commit to topic partiton: {} with  offset: {} ", metadata.getKey(), metadata.getValue());
			} else {
			if(nodes.get(cluster.leader()) == null) {
				nodes.put(cluster.leader(), new ArrayList<TopicPartition>());
			}
			nodes.get(cluster.leader()).add(metadata.getKey());
			}
					
		}
		return nodes;
		
	}
	public boolean resetOffsetsSync(Map<TopicPartition, Long>  offsetResetTimestamps, long timeout) {
		long now = time.milliseconds();
		Node node = client.leastLoadedNode(now);
		if( node == null || !client.ready(node, now) ) 
			return false;
		ClientResponse response = client.send(client.newClientRequest(node, new OffsetResetRequest.Builder(offsetResetTimestamps, 0), now, true, requestTimeoutMs < timeout ? requestTimeoutMs: (int)timeout, null), now);
	    return handleOffsetResetResponse(response, offsetResetTimestamps);	
	}
	
	public boolean handleOffsetResetResponse(ClientResponse response, Map<TopicPartition, Long>  offsetResetTimestamps) {
		 OffsetResetResponse offsetResetResponse = (OffsetResetResponse)response.responseBody();
		 Map<TopicPartition, Exception> result = offsetResetResponse.offsetResetResponse();
		 Set<TopicPartition> failed = new HashSet<>();
		 for(Map.Entry<TopicPartition, Exception> tpResult : result.entrySet()) {
			  Long offsetLong = offsetResetTimestamps.get(tpResult.getKey());
			  String offset ;
			    
			  if( offsetLong == -2L )
			   offset = "TO_EARLIEST" ;
			  else if (offsetLong == -1L) 
			   offset = "TO_LATEST";
			  else offset = Long.toString(offsetLong);
			  if( tpResult.getValue() == null) {
				  subscriptions.requestOffsetReset(tpResult.getKey(), null);
			      log.trace("seek to offset {} for topicpartition  {} is successful", offset, tpResult.getKey());
			  }
			  else {
				  if(tpResult.getValue() instanceof java.sql.SQLException && ((java.sql.SQLException)tpResult.getValue()).getErrorCode() == 25323)
				    subscriptions.requestOffsetReset(tpResult.getKey(), null);
				  else failed.add(tpResult.getKey());
				   
				  log.warn("Failed to update seek for topicpartition {} to offset {}", tpResult.getKey(), offset);
			  }
				  
		}
		subscriptions.resetFailed(failed, time.milliseconds() + retryBackoffMs);
		return true;
	}
	/**
	 * Synchronously commit last consumed offsets if auto commit is enabled.
	 */
	public void maybeAutoCommitOffsetsSync(long now) {
        if (autoCommitEnabled && now >= nextAutoCommitDeadline) {
            this.nextAutoCommitDeadline = now + autoCommitIntervalMs;
            doCommitOffsetsSync();
        }
    }
	
	public void clearSubscription() {
		//doCommitOffsetsSync();
		this.subcriptionSnapshot.clear();			
	}
	
	/**
	 * Synchronously commit offsets.
	 */
	private void doCommitOffsetsSync() {
		Map<TopicPartition, OffsetAndMetadata> allConsumedOffsets = subscriptions.allConsumed();
            
	    try {
	    	commitOffsetsSync(allConsumedOffsets, 0);
        	
	    } catch(Exception exception) {
	    	//nothing to do
	    } finally {
	    	nextAutoCommitDeadline = time.milliseconds() + autoCommitIntervalMs;
	    }
	} 
	
	public void unsubscribe() {
		ClientRequest request = this.client.newClientRequest(null, new UnsubscribeRequest.Builder(), time.milliseconds(), true);
		ClientResponse response = this.client.send(request, time.milliseconds());
		handleUnsubscribeResponse(response);
		
	}
	
	private void handleUnsubscribeResponse(ClientResponse response) {
		UnsubscribeResponse  unsubResponse = (UnsubscribeResponse)response.responseBody();
		for(Map.Entry<String, Exception> responseByTopic: unsubResponse.response().entrySet()) {
			if(responseByTopic.getValue() == null)
				log.trace("Failed to unsubscribe from topic: with exception: ", responseByTopic.getKey(), responseByTopic.getValue());
			else
				log.trace("Unsubscribed from topic: ", responseByTopic.getKey());
		}
	}
	
	/**
     * Return the time to the next needed invocation of {@link #poll(long)}.
     * @param now current time in milliseconds
     * @return the maximum time in milliseconds the caller should wait before the next invocation of poll()
     */
    public long timeToNextPoll(long now, long timeoutMs) {
        if (!autoCommitEnabled)
            return timeoutMs;

        if (now > nextAutoCommitDeadline)
            return 0;

        return Math.min(nextAutoCommitDeadline - now, timeoutMs);
    }

	/**
	 * Closes the AQKafkaConsumer.
	 * Commits last consumed offsets if auto commit enabled
	 * @param timeoutMs
	 */
	public void close(long timeoutMs) throws Exception {
		KafkaException autoCommitException = null;
		if(autoCommitEnabled) {
			Map<TopicPartition, OffsetAndMetadata> allConsumedOffsets = subscriptions.allConsumed();
			try {
	            commitOffsetsSync(subscriptions.allConsumed(), timeoutMs);
	        } catch (Exception exception) {
	        	autoCommitException= new KafkaException("failed to commit consumed messages", exception);
	        }
		}
		this.client.close();
		if(autoCommitException != null)
			throw autoCommitException;
	}

}
