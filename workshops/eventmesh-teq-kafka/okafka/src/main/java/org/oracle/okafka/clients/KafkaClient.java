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

import java.io.Closeable;

import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.AuthenticationException;
import org.oracle.okafka.common.requests.AbstractRequest;

/**
 * The interface for {@link NetworkClient}
 */
public interface KafkaClient extends Closeable {

    /**
     * Check if we are currently ready to send another request to the given node but don't attempt to connect if we
     * aren't.
     *
     * @param node The node to check
     * @param now The current timestamp
     */
    boolean isReady(Node node, long now);

    /**
     * Initiate a connection to the given node (if necessary), and return true if already connected. The readiness of a
     * node will change only when poll is invoked.
     *
     * @param node The node to connect to.
     * @param now The current time
     * @return true iff we are ready to immediately initiate the sending of another request to the given node.
     */
    boolean ready(Node node, long now);

    /**
     * Return the number of milliseconds to wait, based on the connection state, before attempting to send data. When
     * disconnected, this respects the reconnect backoff time. When connecting or connected, this handles slow/stalled
     * connections.
     *
     * @param node The node to check
     * @param now The current timestamp
     * @return The number of milliseconds to wait.
     */
    long connectionDelay(Node node, long now);

    /**
     * Return the number of milliseconds to wait, based on the connection state a before
     * attempting to send data. If the connection has been established but being throttled, return connection delay.
     *
     * @param node the connection to check
     * @param now the current time in ms
     */
    long pollDelayMs(Node node, long now);

    /**
     * Check if the connection of the node has failed, based on the connection state. Such connection failure are
     * usually transient and can be resumed in the next {@link #ready(Node, long)} }
     * call, but there are cases where transient failures needs to be caught and re-acted upon.
     *
     * @param node the node to check
     * @return true iff the connection has failed and the node is disconnected
     */
    boolean connectionFailed(Node node);

    /**
     * Check if authentication to this node has failed, based on the connection state. Authentication failures are
     * propagated without any retries.
     *
     * @param node the node to check
     * @return an AuthenticationException iff authentication has failed, null otherwise
     */
    AuthenticationException authenticationException(Node node);

    /**
     * Queue up the given request for sending. Requests can only be sent on ready connections.
     * @param request The request
     * @param now The current timestamp
     */
    ClientResponse send(ClientRequest request, long now);

    /**
     * Disconnects the connection to a particular node, if there is one.
     * Any pending ClientRequests for this connection will receive disconnections.
     *
     * @param node
     */
    void disconnect(Node node);
    
    void disconnected(Node node, long now);

    /**
     * Closes the connection to a particular node (if there is one).
     *
     * @param node
     */
    void close(Node node);

    /**
     * The first ready node.
     *
     * @param now The current time in ms
     * @return The node connected or ready for connection.
     */
    Node leastLoadedNode(long now);

    /**
     * Return true if there is at least one node with connection in the READY state. Returns false
     * otherwise.
     *
     * @param now the current time
     */
    boolean hasReadyNodes(long now);
    
    long maybeUpdateMetadata(long now);

    /**
     * Create a new ClientRequest.
     *
     * @param node the node to send to
     * @param requestBuilder the request builder to use
     * @param createdTimeMs the time in milliseconds to use as the creation time of the request
     * @param expectResponse true iff we expect a response
     */
    ClientRequest newClientRequest(Node node, AbstractRequest.Builder<?> requestBuilder,
                                   long createdTimeMs, boolean expectResponse);

    /**
     * Create a new ClientRequest.
     *
     * @param node the node to send to
     * @param requestBuilder the request builder to use
     * @param createdTimeMs the time in milliseconds to use as the creation time of the request
     * @param expectResponse true if we expect a response
     * @param requestTimeoutMs Upper bound time in milliseconds to await a response.
     * @param callback the callback to invoke when we get a response
     */
    ClientRequest newClientRequest(Node node,
                                   AbstractRequest.Builder<?> requestBuilder,
                                   long createdTimeMs,
                                   boolean expectResponse,
                                   int requestTimeoutMs,
                                   RequestCompletionHandler callback);

}
