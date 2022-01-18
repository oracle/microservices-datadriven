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

package org.oracle.okafka.clients;

import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.AuthenticationException;
import org.oracle.okafka.common.errors.InvalidLoginCredentialsException;
import org.oracle.okafka.common.metrics.Sensor;
import org.oracle.okafka.common.network.AQClient;
import org.oracle.okafka.common.requests.AbstractRequest;
import org.oracle.okafka.common.requests.MetadataRequest;
import org.oracle.okafka.common.requests.MetadataResponse;
import org.oracle.okafka.common.requests.RequestHeader;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.Time;
import org.slf4j.Logger;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;

import javax.jms.JMSException;
import javax.jms.JMSSecurityException;

/**
 * A network client for synchronous request/response network i/o. This is an internal class used to implement the
 * user-facing producer and consumer clients.
 * <p>
 * This class is not thread-safe!
 */
public class NetworkClient implements KafkaClient {

    private final Logger log;

    /* the selector used to perform network i/o */
    private final AQClient aqClient;

    private final MetadataUpdater metadataUpdater;

    private final Random randOffset;

    /* the state of each node's connection */
    private final ClusterConnectionStates connectionStates;

    /* the socket send buffer size in bytes */
    private final int socketSendBuffer;

    /* the socket receive size buffer in bytes */
    private final int socketReceiveBuffer;

    /* the client id used to identify this client in requests to the server */
    private final String clientId;

    /* the current correlation id to use when sending requests to servers */
    private int correlation;

    /* default timeout for individual requests to await acknowledgement from servers */
    private final int defaultRequestTimeoutMs;

    /* time in ms to wait before retrying to create connection to a server */
    private final long reconnectBackoffMs;

    private final Time time;

    private final Sensor throttleTimeSensor;

    public NetworkClient(AQClient aqClient,
                         Metadata metadata,
                         String clientId,
                         long reconnectBackoffMs,
                         long reconnectBackoffMax,
                         int socketSendBuffer,
                         int socketReceiveBuffer,
                         int defaultRequestTimeoutMs,
                         Time time,
                         LogContext logContext) {
        this(null,
             metadata,
             aqClient,
             clientId,
             reconnectBackoffMs,
             reconnectBackoffMax,
             socketSendBuffer,
             socketReceiveBuffer,
             defaultRequestTimeoutMs,
             time,
             null,
             logContext);
    }

    public NetworkClient(AQClient aqClient,
            Metadata metadata,
            String clientId,
            long reconnectBackoffMs,
            long reconnectBackoffMax,
            int socketSendBuffer,
            int socketReceiveBuffer,
            int defaultRequestTimeoutMs,
            Time time,
            Sensor throttleTimeSensor,
            LogContext logContext) {
        this(null,
             metadata,
             aqClient,
             clientId,
             reconnectBackoffMs,
             reconnectBackoffMax,
             socketSendBuffer,
             socketReceiveBuffer,
             defaultRequestTimeoutMs,
             time,
             throttleTimeSensor,
             logContext);
    }

    public NetworkClient(AQClient aqClient,
                         MetadataUpdater metadataUpdater,
                         String clientId,
                         long reconnectBackoffMs,
                         long reconnectBackoffMax,
                         int socketSendBuffer,
                         int socketReceiveBuffer,
                         int defaultRequestTimeoutMs,
                         Time time,
                         LogContext logContext) {
        this(metadataUpdater,
             null,
             aqClient,
             clientId,
             reconnectBackoffMs,
             reconnectBackoffMax,
             socketSendBuffer,
             socketReceiveBuffer,
             defaultRequestTimeoutMs,
             time,
             null,
             logContext);
    }

    private NetworkClient(MetadataUpdater metadataUpdater,
                          Metadata metadata,
                          AQClient aqClient,
                          String clientId,
                          long reconnectBackoffMs,
                          long reconnectBackoffMax,
                          int socketSendBuffer,
                          int socketReceiveBuffer,
                          int defaultRequestTimeoutMs,
                          Time time,
                          Sensor throttleTimeSensor,
                          LogContext logContext) {
        /* It would be better if we could pass `DefaultMetadataUpdater` from the public constructor, but it's not
         * possible because `DefaultMetadataUpdater` is an inner class and it can only be instantiated after the
         * super constructor is invoked.
         */
        if (metadataUpdater == null) {
            if (metadata == null)
                throw new IllegalArgumentException("`metadata` must not be null");
            this.metadataUpdater = new DefaultMetadataUpdater(metadata);
        } else {
            this.metadataUpdater = metadataUpdater;
        }
        this.aqClient = aqClient;
        this.clientId = clientId;
        this.connectionStates = new ClusterConnectionStates(reconnectBackoffMs, reconnectBackoffMax);
        this.socketSendBuffer = socketSendBuffer;
        this.socketReceiveBuffer = socketReceiveBuffer;
        this.correlation = 0;
        this.randOffset = new Random();
        this.defaultRequestTimeoutMs = defaultRequestTimeoutMs;
        this.reconnectBackoffMs = reconnectBackoffMs;
        this.time = time;
        this.throttleTimeSensor = throttleTimeSensor;
        this.log = logContext.logger(NetworkClient.class);
    }

    /**
     * Begin connecting to the given node, return true if we are already connected and ready to send to that node.
     *
     * @param node The node to check
     * @param now The current timestamp
     * @return True if we are ready to send to the given node
     */
    @Override
    public boolean ready(Node node, long now) {
        if (node.isEmpty())
            throw new IllegalArgumentException("Cannot connect to empty node " + node);

        if (isReady(node, now))
            return true;
        if (connectionStates.canConnect(node, now)) {
            // if we are interested in sending to a node and we don't have a connection to it, initiate one
            return initiateConnect(node, now);
        }

        return false;
    }

    // Visible for testing
    boolean canConnect(Node node, long now) {
        return connectionStates.canConnect(node, now);
    }

    /**
     * Disconnects the connection to a particular node, if there is one.
     * Any pending ClientRequests for this connection will receive disconnections.
     *
     * @param node The id of the node
     */
    @Override
    public void disconnect(Node node) {
       
    }
    
    public ClusterConnectionStates getConnectionStates() {
    	return this.connectionStates;
    }

    /**
     * Closes the connection to a particular node (if there is one).
     *
     * @param node the node
     */
    @Override
    public void close(Node node) {
    	aqClient.close(node);
        connectionStates.remove(node);
    }

    /**
     * Returns the number of milliseconds to wait, based on the connection state, before attempting to send data. When
     * disconnected, this respects the reconnect backoff time. When connecting or connected, this handles slow/stalled
     * connections.
     *
     * @param node The node to check
     * @param now The current timestamp
     * @return The number of milliseconds to wait.
     */
    @Override
    public long connectionDelay(Node node, long now) {
        return connectionStates.connectionDelay(node, now);
    }

    /**
     * Return the poll delay in milliseconds based on both connection and throttle delay.
     * @param node the connection to check
     * @param now the current time in ms
     */
    @Override
    public long pollDelayMs(Node node, long now) {
        return connectionStates.pollDelayMs(node, now);
    }

    /**
     * Check if the connection of the node has failed, based on the connection state. Such connection failure are
     * usually transient and can be resumed in the next {@link #ready(Node, long)} }
     * call, but there are cases where transient failures needs to be caught and re-acted upon.
     *
     * @param node the node to check
     * @return true iff the connection has failed and the node is disconnected
     */
    @Override
    public boolean connectionFailed(Node node) {
        return connectionStates.isDisconnected(node);
    }

    /**
     * Check if authentication to this node has failed, based on the connection state. Authentication failures are
     * propagated without any retries.
     *
     * @param node the node to check
     * @return an AuthenticationException iff authentication has failed, null otherwise
     */
    @Override
    public AuthenticationException authenticationException(Node node) {
        return connectionStates.authenticationException(node);
    }

    /**
     * Check if the node  is ready to send more requests.
     *
     * @param node The node
     * @param now The current time in ms
     * @return true if the node is ready
     */
    @Override
    public boolean isReady(Node node, long now) {
        // if we need to update our metadata now declare all requests unready to make metadata requests first
        // priority
        return !metadataUpdater.isUpdateDue(now) && canSendRequest(node, now);
    }

    /**
     * Are we connected and ready and able to send more requests to the given connection?
     *
     * @param node The node
     * @param now the current timestamp
     */
    private boolean canSendRequest(Node node, long now) {
        return this.connectionStates.isReady(node, now);
    
    }

    /**
     * Send the given request. Requests can only be sent out to ready nodes.
     * @param request The request
     * @param now The current timestamp
     */
    @Override
    public ClientResponse send(ClientRequest request, long now) {
        return doSend(request, false, now);
    }
    
    private void sendInternalMetadataRequest(MetadataRequest.Builder builder, Node node, long now) {

    	ClientRequest clientRequest = newClientRequest(node, builder, now, true);

    	ClientResponse response = doSend(clientRequest, true, now);

    	log.debug("Got response for metadata request {} from node {}", builder, node);

    	metadataUpdater.handleCompletedMetadataResponse(response.requestHeader(), time.milliseconds(), (MetadataResponse)response.responseBody());
    }

    private ClientResponse doSend(ClientRequest clientRequest, boolean isInternalRequest, long now) {
        Node node = clientRequest.destination();

        if (node !=null && !isInternalRequest) {
            // If this request came from outside the NetworkClient, validate
            // that we can send data.  If the request is internal, we trust
            // that internal code has done this validation.  Validation
            // will be slightly different for some internal requests (for
            // example, ApiVersionsRequests can be sent prior to being in
            // READY state.)
            if (!canSendRequest(node, now))
                throw new IllegalStateException("Attempt to send a request to node " + node + " which is not ready.");
        }
        // TODO Debugging Send
        log.debug("NetworkClient Calling :: before aqClient send ");
       ClientResponse response =  aqClient.send(clientRequest);

       handleDisconnection(node, response.wasDisconnected(), time.milliseconds());
       return response;
    }

    @Override
    public boolean hasReadyNodes(long now) {
        return connectionStates.hasReadyNodes(now);
    }
    
    @Override 
    public long maybeUpdateMetadata(long now) {
    	return metadataUpdater.maybeUpdate(now);
    }

    /**
     * Close the network client
     */
    @Override
    public void close() {
        aqClient.close();
        this.metadataUpdater.close();
    }

    /**
     * Choose first ready node.
     *
     * @return The node ready.
     */
    @Override
    public Node leastLoadedNode(long now) {
    	List<Node> nodes = this.metadataUpdater.fetchNodes();
        Node found = null;
        int offset = this.randOffset.nextInt(nodes.size());
        for (int i = 0; i < nodes.size(); i++) {
            int idx = (offset + i) % nodes.size();
            Node node = nodes.get(idx);
            if (isReady(node, now)) {
                // if we find an established connection with no in-flight requests we can stop right away
                log.debug("Found least loaded node {}", node);
                return node;
            } else if (!this.connectionStates.isBlackedOut(node, now) ) {
                // otherwise if this is the best we have found so far, record that
                found = node;
            } else if (log.isTraceEnabled()) {
                log.debug("Removing node {} from least loaded node selection: is-blacked-out: {}",
                        node, this.connectionStates.isBlackedOut(node, now));
            }
        }

        if (found != null)
            log.debug("Found least loaded node {}", found);
        else
            log.debug("Least loaded node selection failed to find an available node");

        return found;
    }
    
    @Override
    public void disconnected(Node node, long now) {
    	this.connectionStates.disconnected(node, now);
    }
    
   
    /**
     * Initiate a connection to the given node
     */
    private boolean initiateConnect(Node node, long now) {
        try {
            log.debug("Initiating connection to node {}", node);

            this.connectionStates.connecting(node, now);
            aqClient.connect(node);

            this.connectionStates.ready(node);
            log.trace("Connection is established to node {}", node);

        } catch(Exception e) {
            if(e instanceof JMSException) {
        	  if(((JMSException)e).getErrorCode().equals("1405")) {
        		  log.error("create session privilege is not assigned", e.getMessage());
        		  log.info("create session, execute on dbms_aqin, execute on dbms_aqadm privileges required for producer to work");
        	  } else if (((JMSException)e).getErrorCode().equals("6550")) {
        		  log.error("execute on dbms_aqin is not assigned", e.getMessage());
        		  log.info("create session, execute on dbms_aqin, dbms_aqadm , dbms_aqjms privileges required for producer or consumer to work");
        	  }
      	  
        	}
        	/* attempt failed, we'll try again after the backoff */
            connectionStates.disconnected(node, now);
            /* maybe the problem is our metadata, update it */
            metadataUpdater.requestUpdate();                     

        	log.warn("Error connecting to node {}", node, e);
        	if(e instanceof JMSSecurityException || ((JMSException)e).getErrorCode().equals("12505"))
  				throw new InvalidLoginCredentialsException("Invalid login details provided:" + e.getMessage());
        	return false;
        }
        return true;
    }
    
    private void handleDisconnection(Node node, boolean disconnected, long now) {
    	if(disconnected) {
    		disconnected(node, now);
    		metadataUpdater.requestUpdate();
    	}	
    }

    class DefaultMetadataUpdater implements MetadataUpdater {

        /* the current cluster metadata */
        private final Metadata metadata;

        /* true iff there is a metadata request that has been sent and for which we have not yet received a response */
        private boolean metadataFetchInProgress;

        DefaultMetadataUpdater(Metadata metadata) {
            this.metadata = metadata;
            this.metadataFetchInProgress = false;
        }

        @Override
        public List<Node> fetchNodes() {
            return metadata.fetch().nodes();
        }

        @Override
        public boolean isUpdateDue(long now) {
             return !this.metadataFetchInProgress && this.metadata.timeToNextUpdate(now) == 0;
        }

        @Override
        public long maybeUpdate(long now) {
        	// should we update our metadata?
            long timeToNextMetadataUpdate = metadata.timeToNextUpdate(now);
            long waitForMetadataFetch = this.metadataFetchInProgress ? defaultRequestTimeoutMs : 0;

            long metadataTimeout = Math.max(timeToNextMetadataUpdate, waitForMetadataFetch);

            if (metadataTimeout > 0) {
                return metadataTimeout;
            }

            Node node = leastLoadedNode(now);
            if (node == null) {
                log.debug("Give up sending metadata request since no node is available");
                return reconnectBackoffMs;
            }

            return maybeUpdate(now, node);
        }
        
        @Override
        public void handleCompletedMetadataResponse(RequestHeader requestHeader, long now, MetadataResponse response) {
            this.metadataFetchInProgress = false;
            Cluster cluster = response.cluster(metadata.getConfigs());

         // check if any topics metadata failed to get updated
            Map<String, Exception> errors = response.topicErrors();
            if (!errors.isEmpty())
                log.warn("Error while fetching metadata : {}", errors);

            // don't update the cluster if there are no valid nodes...the topic we want may still be in the process of being
            // created which means we will get errors and no nodes until it exists
            if (cluster.nodes().size() > 0) {
                this.metadata.update(cluster, null, now);
            } else {
                log.trace("Ignoring empty metadata response with correlation id {}.", requestHeader.correlationId());
                this.metadata.failedUpdate(now, null);
            }
        }

        @Override
        public void handleDisconnection(String destination) {
            //not used
        }

        @Override
        public void handleAuthenticationFailure(AuthenticationException exception) {
            metadataFetchInProgress = false;
            if (metadata.updateRequested())
                metadata.failedUpdate(time.milliseconds(), exception);
        }

        @Override
        public void requestUpdate() {
            this.metadata.requestUpdate();
        }

        @Override
        public void close() {
        	aqClient.close();
            this.metadata.close();
        }
        
        /**
         * Add a metadata request to the list of sends if we can make one
         */
        private long maybeUpdate(long now, Node node) {

            if (!canSendRequest(node, now)) {
            	 if (connectionStates.canConnect(node, now)) {
                     // we don't have a connection to this node right now, make one
                     log.debug("Initialize connection to node {} for sending metadata request", node);
                     try {
                     	if( !initiateConnect(node, now))
                     		return reconnectBackoffMs;
                     } catch(InvalidLoginCredentialsException ilc) {
                     	log.error("Failed to connect to node {} with error {}", node, ilc.getMessage());
                     	this.metadata.failedUpdate(now, new AuthenticationException(ilc.getMessage()));
                     	return reconnectBackoffMs;
                     }   
                 } else return reconnectBackoffMs;            
            }
            this.metadataFetchInProgress = true;
            MetadataRequest.Builder metadataRequest;
            if (metadata.needMetadataForAllTopics())
                metadataRequest = MetadataRequest.Builder.allTopics();
            else           	
             metadataRequest = new MetadataRequest.Builder(new ArrayList<>(metadata.topics()),
                        metadata.allowAutoTopicCreation());
            log.debug("Sending metadata request {} to node {}", metadataRequest, node);
            sendInternalMetadataRequest(metadataRequest, node, now);
            return defaultRequestTimeoutMs;
        }

    }

    @Override
    public ClientRequest newClientRequest(Node node,
                                          AbstractRequest.Builder<?> requestBuilder,
                                          long createdTimeMs,
                                          boolean expectResponse) {
        return newClientRequest(node, requestBuilder, createdTimeMs, expectResponse, defaultRequestTimeoutMs, null);
    }

    @Override
    public ClientRequest newClientRequest(Node node,
                                          AbstractRequest.Builder<?> requestBuilder,
                                          long createdTimeMs,
                                          boolean expectResponse,
                                          int requestTimeoutMs,
                                          RequestCompletionHandler callback) {
        return new ClientRequest(node, requestBuilder, correlation++, clientId, createdTimeMs, expectResponse,
                defaultRequestTimeoutMs, callback);
    }

}
