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
 * Methods removed:
 *                throttle(String , long)
 */

package org.oracle.okafka.clients;

import java.util.concurrent.ThreadLocalRandom;

import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.AuthenticationException;

import java.util.HashMap;
import java.util.Map;

/**
 * The state of our connection to each node in the cluster.
 *
 */
public final class ClusterConnectionStates {
    private final long reconnectBackoffInitMs;
    private final long reconnectBackoffMaxMs;
    private final static int RECONNECT_BACKOFF_EXP_BASE = 2;
    private final double reconnectBackoffMaxExp;
    private final Map<Node, NodeConnectionState> nodeState;

    public ClusterConnectionStates(long reconnectBackoffMs, long reconnectBackoffMaxMs) {
        this.reconnectBackoffInitMs = reconnectBackoffMs;
        this.reconnectBackoffMaxMs = reconnectBackoffMaxMs;
        this.reconnectBackoffMaxExp = Math.log(this.reconnectBackoffMaxMs / (double) Math.max(reconnectBackoffMs, 1)) / Math.log(RECONNECT_BACKOFF_EXP_BASE);
        this.nodeState = new HashMap<>();
    }

    /**
     * Return true if we can currently initiate a new connection. This will be the case if we are not
     * connected and haven't been connected for at least the minimum reconnection backoff period.
     * @param Node the node to check for onnection
     * @param now the current time in ms
     * @return true if we can initiate a new connection
     */
    public boolean canConnect(Node node, long now) {
        NodeConnectionState state = nodeState.get(node);

        if (state == null)
            return true;
        else
            return state.state.isDisconnected() &&
                   now - state.lastConnectAttemptMs >= state.reconnectBackoffMs;
    }

    /**
     * Return true if we are disconnected from the given node and can't re-establish a connection yet.
     * @param node the connection to check
     * @param now the current time in ms
     */
    public boolean isBlackedOut(Node node, long now) {
        NodeConnectionState state = nodeState.get(node);
        if (state == null)
            return false;
        else
            return state.state.isDisconnected() &&
                   now - state.lastConnectAttemptMs < state.reconnectBackoffMs;
    }

    /**
     * Returns the number of milliseconds to wait, based on the connection state, before attempting to send data. When
     * disconnected, this respects the reconnect backoff time. When connecting or connected, this handles slow/stalled
     * connections.
     * @param node the connection to check
     * @param now the current time in ms
     */
    public long connectionDelay(Node node, long now) {
        NodeConnectionState state = nodeState.get(node);
        if (state == null) return 0;
        long timeWaited = now - state.lastConnectAttemptMs;
        if (state.state.isDisconnected()) {
            return Math.max(state.reconnectBackoffMs - timeWaited, 0);
        } else {
            return Long.MAX_VALUE;
        }
    }

    /**
     * Enter the connecting state for the given connection.
     * @param node  node for the connection
     * @param now the current time
     */
    public void connecting(Node node, long now) {
        if (nodeState.containsKey(node)) {
            NodeConnectionState nodestate = nodeState.get(node);
            nodestate.lastConnectAttemptMs = now;
            nodestate.state = ConnectionState.CONNECTING;
        } else {
            nodeState.put(node, new NodeConnectionState(ConnectionState.CONNECTING, now,
                this.reconnectBackoffInitMs));
        }
    }

    /**
     * Enter the disconnected state for the given node.
     * @param node the connection we have disconnected
     * @param now the current time
     */
    public void disconnected(Node node, long now) {
        NodeConnectionState nodeState = nodeState(node);
        nodeState.state = ConnectionState.DISCONNECTED;
        nodeState.lastConnectAttemptMs = now;
        updateReconnectBackoff(nodeState);
    }

    /**
     * Return the number of milliseconds to wait, based on the connection state before
     * attempting to send data. Return connection delay.
     * @param node the connection to check
     * @param now the current time in ms
     */
    public long pollDelayMs(Node node, long now) {
            return connectionDelay(node, now);
    }

    /**
     * Enter the ready state for the given node.
     * @param node the connection identifier
     */
    public void ready(Node node) {
        NodeConnectionState nodeState = nodeState(node);
        nodeState.state = ConnectionState.READY;
        nodeState.authenticationException = null;
        resetReconnectBackoff(nodeState);
    }
    
    /**
     * Enter the authentication failed state for the given node.
     * @param node the node to which authentication failed
     * @param now the current time
     * @param exception the authentication exception
     */
    public void authenticationFailed(Node node, long now, AuthenticationException exception) {
        NodeConnectionState nodeState = nodeState(node);
        nodeState.authenticationException = exception;
        nodeState.state = ConnectionState.AUTHENTICATION_FAILED;
        nodeState.lastConnectAttemptMs = now;
        updateReconnectBackoff(nodeState);
    }

    /**
     * Return true if the connection is in the READY state and currently not throttled.
     *
     * @param node the node for connection 
     * @param now the current time
     */
    public boolean isReady(Node node, long now) {
        return isReady(nodeState.get(node), now);
    }

    private boolean isReady(NodeConnectionState state, long now) {
        return state != null && state.state == ConnectionState.READY;
    }

    /**
     * Return true if there is at least one node with connection in the READY state. Returns false otherwise.
     *
     * @param now the current time
     */
    public boolean hasReadyNodes(long now) {
        for (Map.Entry<Node, NodeConnectionState> entry : nodeState.entrySet()) {
            if (isReady(entry.getValue(), now)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Return true if the connection has been established
     * @param id The id of the node to check
     */
    public boolean isConnected(Node node) {
        NodeConnectionState state = nodeState.get(node);
        return state != null && state.state.isConnected();
    }

    /**
     * Return true if the connection has been disconnected
     * @param node the node to check
     */
    public boolean isDisconnected(Node node) {
        NodeConnectionState state = nodeState.get(node);
        return state != null && state.state.isDisconnected();
    }

    /**
     * Return authentication exception if an authentication error occurred
     * @param node the node to check
     */
    public AuthenticationException authenticationException(Node node) {
        NodeConnectionState state = nodeState.get(node);
        return state != null ? state.authenticationException : null;
    }

    /**
     * Resets the failure count for a node and sets the reconnect backoff to the base
     * value configured via reconnect.backoff.ms
     *
     * @param nodeState The node state object to update
     */
    private void resetReconnectBackoff(NodeConnectionState nodeState) {
        nodeState.failedAttempts = 0;
        nodeState.reconnectBackoffMs = this.reconnectBackoffInitMs;
    }

    /**
     * Update the node reconnect backoff exponentially.
     * The delay is reconnect.backoff.ms * 2**(failures - 1) * (+/- 20% random jitter)
     * Up to a (pre-jitter) maximum of reconnect.backoff.max.ms
     *
     * @param nodeState The node state object to update
     */
    private void updateReconnectBackoff(NodeConnectionState nodeState) {
        if (this.reconnectBackoffMaxMs > this.reconnectBackoffInitMs) {
            nodeState.failedAttempts += 1;
            double backoffExp = Math.min(nodeState.failedAttempts - 1, this.reconnectBackoffMaxExp);
            double backoffFactor = Math.pow(RECONNECT_BACKOFF_EXP_BASE, backoffExp);
            long reconnectBackoffMs = (long) (this.reconnectBackoffInitMs * backoffFactor);
            // Actual backoff is randomized to avoid connection storms.
            double randomFactor = ThreadLocalRandom.current().nextDouble(0.8, 1.2);
            nodeState.reconnectBackoffMs = (long) (randomFactor * reconnectBackoffMs);           
        }
    }

    /**
     * Remove the given node from the tracked connection states. The main difference between this and `disconnected`
     * is the impact on `connectionDelay`: it will be 0 after this call whereas `reconnectBackoffMs` will be taken
     * into account after `disconnected` is called.
     *
     * @param node the connection to remove
     */
    public void remove(Node node) {
        nodeState.remove(node);
    }

    /**
     * Get the state of a given connection.
     * @param node  node to check
     * @return the state of our connection
     */
    public ConnectionState connectionState(Node node) {
        return nodeState(node).state;
    }

    /**
     * Get the state of a given node.
     * @param node the connection to fetch the state for
     */
    private NodeConnectionState nodeState(Node node) {
        NodeConnectionState state = this.nodeState.get(node);
        if (state == null)
            throw new IllegalStateException("No entry found for connection " + node);
        return state;
    }

    /**
     * The state of our connection to a node.
     */
    private static class NodeConnectionState {

        ConnectionState state;
        AuthenticationException authenticationException;
        long lastConnectAttemptMs;
        long failedAttempts;
        long reconnectBackoffMs;
        // Connection is being throttled if current time < throttleUntilTimeMs.
        long throttleUntilTimeMs;

        public NodeConnectionState(ConnectionState state, long lastConnectAttempt, long reconnectBackoffMs) {
            this.state = state;
            this.authenticationException = null;
            this.lastConnectAttemptMs = lastConnectAttempt;
            this.failedAttempts = 0;
            this.reconnectBackoffMs = reconnectBackoffMs;
            this.throttleUntilTimeMs = 0;
        }

        public String toString() {
            return "NodeState(" + state + ", " + lastConnectAttemptMs + ", " + failedAttempts + ", " + throttleUntilTimeMs + ")";
        }
    }
}
