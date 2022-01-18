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

import org.oracle.okafka.clients.producer.internals.ProduceRequest;
import org.oracle.okafka.clients.producer.internals.ProduceResponse;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.AuthenticationException;
import org.oracle.okafka.common.errors.InvalidTopicException;
import org.oracle.okafka.common.protocol.ApiKeys;
import org.oracle.okafka.common.requests.AbstractRequest;
import org.oracle.okafka.common.requests.AbstractResponse;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.test.TestCondition;
import org.oracle.okafka.test.TestUtils;

import java.util.*;
import java.util.concurrent.ConcurrentLinkedDeque;

/**
 * A mock network client for use testing code
 */
public class MockClient implements KafkaClient {

    private int correlation;
    private final Time time;
    private final Metadata metadata;
    private Set<String> unavailableTopics;
    private Cluster cluster;
    private Node node = null;
    private final Set<Node> ready = new HashSet<>();

    // Nodes awaiting reconnect backoff, will not be chosen by leastLoadedNode
    private final TransientSet<Node> blackedOut;
    // Nodes which will always fail to connect, but can be chosen by leastLoadedNode
    private final TransientSet<Node> unreachable;
    // Nodes which have a delay before ultimately succeeding to connect
    private final TransientSet<Node> delayedReady;

    private long requests = 0;
    private final Map<Node, Long> pendingAuthenticationErrors = new HashMap<>();
    private final Map<Node, AuthenticationException> authenticationErrors = new HashMap<>();
    private final Queue<MetadataUpdate> metadataUpdates = new ConcurrentLinkedDeque<>();


    public MockClient(Time time) {
        this(time, null);
    }

    public MockClient(Time time, Metadata metadata) {
        this.time = time;
        this.metadata = metadata;
        this.unavailableTopics = Collections.emptySet();
        this.blackedOut = new TransientSet<>(time);
        this.unreachable = new TransientSet<>(time);
        this.delayedReady = new TransientSet<>(time);
    }

    @Override
    public boolean isReady(Node node, long now) {
        return ready.contains(node);
    }

    @Override
    public boolean ready(Node node, long now) {
        if (blackedOut.contains(node, now))
            return false;

        if (unreachable.contains(node, now)) {
            blackout(node, 100);
            return false;
        }

        if (delayedReady.contains(node, now))
            return false;

        ready.add(node);
        return true;
    }

    @Override
    public long connectionDelay(Node node, long now) {
        return blackedOut.expirationDelayMs(node, now);
    }

    @Override
    public long pollDelayMs(Node node, long now) {
        return connectionDelay(node, now);
    }

    public void blackout(Node node, long durationMs) {
        blackedOut.add(node, durationMs);
    }

    public void setUnreachable(Node node, long durationMs) {
        disconnect(node);
        unreachable.add(node, durationMs);
    }

    public void delayReady(Node node, long durationMs) {
        delayedReady.add(node, durationMs);
    }

    public void authenticationFailed(Node node, long blackoutMs) {
        pendingAuthenticationErrors.remove(node);
        authenticationErrors.put(node, new AuthenticationException("Authentication failed"));
        disconnect(node);
        blackout(node, blackoutMs);
    }

    public void createPendingAuthenticationError(Node node, long blackoutMs) {
        pendingAuthenticationErrors.put(node, blackoutMs);
    }

    @Override
    public boolean connectionFailed(Node node) {
        return blackedOut.contains(node);
    }

    @Override
    public AuthenticationException authenticationException(Node node) {
        return authenticationErrors.get(node);
    }

    @Override 
    public void disconnected(Node node, long now) {
    	return ;
    }
    @Override
    public void disconnect(Node node) {
        ready.remove(node);
    }

    @Override
    public ClientResponse send(ClientRequest request, long now) {
    	requests++;
        ClientResponse response = dummyResponse(request);
        requests--;
        return response;
    }
    
    private ClientResponse dummyResponse(ClientRequest request) {
    	try {
    		Thread.sleep(30000);
    	} catch(Exception e) {
    		
    	}
    	if(request.apiKey() == ApiKeys.PRODUCE ) {
    		ProduceRequest.Builder builder = (ProduceRequest.Builder)request.requestBuilder();
    		ProduceRequest produceRequest = builder.build();
    		return new ClientResponse(request.makeHeader(), request.callback(), request.destination(), 
	                   request.createdTimeMs(), time.milliseconds(), true, 
	                   new ProduceResponse(produceRequest.getTopicpartition(), new ProduceResponse.PartitionResponse(new InvalidTopicException("This exception can be retried"))));
    	}
    	return null;
    }

    @Override
    public long maybeUpdateMetadata(long now) {

        if (metadata != null && metadata.updateRequested()) {
            MetadataUpdate metadataUpdate = metadataUpdates.poll();
            if (cluster != null)
                metadata.update(cluster, this.unavailableTopics, time.milliseconds());
            if (metadataUpdate == null)
                metadata.update(metadata.fetch(), this.unavailableTopics, time.milliseconds());
            else {
                if (metadataUpdate.expectMatchRefreshTopics
                    && !metadata.topics().equals(metadataUpdate.cluster.topics())) {
                    throw new IllegalStateException("The metadata topics does not match expectation. "
                                                        + "Expected topics: " + metadataUpdate.cluster.topics()
                                                        + ", asked topics: " + metadata.topics());
                }
                this.unavailableTopics = metadataUpdate.unavailableTopics;
                metadata.update(metadataUpdate.cluster, metadataUpdate.unavailableTopics, time.milliseconds());
            }
        }
        return 0;
    }

    public void waitForRequests(final int minRequests, long maxWaitMs) throws InterruptedException {
        TestUtils.waitForCondition(new TestCondition() {
            @Override
            public boolean conditionMet() {
                return requests >= minRequests;
            }
        }, maxWaitMs, "Expected requests have not been sent");
    }

    public void reset() {
        ready.clear();
        blackedOut.clear();
        unreachable.clear();
        requests = 0;
        metadataUpdates.clear();
        authenticationErrors.clear();
    }

    public boolean hasPendingMetadataUpdates() {
        return !metadataUpdates.isEmpty();
    }

    public void prepareMetadataUpdate(Cluster cluster, Set<String> unavailableTopics) {
        metadataUpdates.add(new MetadataUpdate(cluster, unavailableTopics, false));
    }

    public void prepareMetadataUpdate(Cluster cluster,
                                      Set<String> unavailableTopics,
                                      boolean expectMatchMetadataTopics) {
        metadataUpdates.add(new MetadataUpdate(cluster, unavailableTopics, expectMatchMetadataTopics));
    }

    public void setNode(Node node) {
        this.node = node;
    }

    public void cluster(Cluster cluster) {
        this.cluster = cluster;
    }

    @Override
    public boolean hasReadyNodes(long now) {
        return !ready.isEmpty();
    }

    @Override
    public ClientRequest newClientRequest(Node node, AbstractRequest.Builder<?> requestBuilder, long createdTimeMs,
                                          boolean expectResponse) {
        return newClientRequest(node, requestBuilder, createdTimeMs, expectResponse, 5000, null);
    }

    @Override
    public ClientRequest newClientRequest(Node node,
                                          AbstractRequest.Builder<?> requestBuilder,
                                          long createdTimeMs,
                                          boolean expectResponse,
                                          int requestTimeoutMs,
                                          RequestCompletionHandler callback) {
        return new ClientRequest(node, requestBuilder, correlation++, "mockClientId", createdTimeMs,
                expectResponse, requestTimeoutMs, callback);
    }

    @Override
    public void close() {
        metadata.close();
    }

    @Override
    public void close(Node node) {
        ready.remove(node);
    }

    @Override
    public Node leastLoadedNode(long now) {
        // Consistent with NetworkClient, we do not return nodes awaiting reconnect backoff
        if (blackedOut.contains(node, now))
            return null;
        return this.node;
    }

    /**
     * The RequestMatcher provides a way to match a particular request to a response prepared
     * through {@link #prepareResponse(RequestMatcher, AbstractResponse)}. Basically this allows testers
     * to inspect the request body for the type of the request or for specific fields that should be set,
     * and to fail the test if it doesn't match.
     */
    public interface RequestMatcher {
        boolean matches(AbstractRequest body);
    }

    private static class MetadataUpdate {
        final Cluster cluster;
        final Set<String> unavailableTopics;
        final boolean expectMatchRefreshTopics;
        MetadataUpdate(Cluster cluster, Set<String> unavailableTopics, boolean expectMatchRefreshTopics) {
            this.cluster = cluster;
            this.unavailableTopics = unavailableTopics;
            this.expectMatchRefreshTopics = expectMatchRefreshTopics;
        }
    }

    private static class TransientSet<T> {
        // The elements in the set mapped to their expiration timestamps
        private final Map<T, Long> elements = new HashMap<>();
        private final Time time;

        private TransientSet(Time time) {
            this.time = time;
        }

        boolean contains(T element) {
            return contains(element, time.milliseconds());
        }

        boolean contains(T element, long now) {
            return expirationDelayMs(element, now) > 0;
        }

        void add(T element, long durationMs) {
            elements.put(element, time.milliseconds() + durationMs);
        }

        long expirationDelayMs(T element, long now) {
            Long expirationTimeMs = elements.get(element);
            if (expirationTimeMs == null) {
                return 0;
            } else if (now > expirationTimeMs) {
                elements.remove(element);
                return 0;
            } else {
                return expirationTimeMs - now;
            }
        }

        void clear() {
            elements.clear();
        }

    }

}
