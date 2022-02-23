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
 *                versionMismatch()
 *                authenticationEception()
 */

package org.oracle.okafka.clients;

import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.requests.AbstractResponse;
import org.oracle.okafka.common.requests.RequestHeader;
/**
 * A response from the server. Contains both the body of the response as well as the correlated request
 * metadata that was originally sent.
 */
public class ClientResponse {
	private final RequestHeader requestHeader;
    private final RequestCompletionHandler callback;
    private final Node destination;
    private final long receivedTimeMs;
    private final long latencyMs;
    private final boolean disconnected;
    private final AbstractResponse responseBody;

    /**
     * @param requestHeader The header of the corresponding request
     * @param callback The callback to be invoked
     * @param createdTimeMs The unix timestamp when the corresponding request was created
     * @param destination The node the corresponding request was sent to
     * @param receivedTimeMs The unix timestamp when this response was received
     * @param disconnected Whether the client disconnected before fully reading a response
     * @param responseBody The response contents (or null)
     */
    public ClientResponse(RequestHeader requestHeader,
    		              RequestCompletionHandler callback,
                          Node destination,
                          long createdTimeMs,
                          long receivedTimeMs,
                          boolean disconnected,
                          AbstractResponse responseBody) {
    	this.requestHeader = requestHeader;
        this.callback = callback;
        this.destination = destination;
        this.receivedTimeMs = receivedTimeMs;
        this.latencyMs = receivedTimeMs - createdTimeMs;
        this.disconnected = disconnected;
        this.responseBody = responseBody;
    }

    public long receivedTimeMs() {
        return receivedTimeMs;
    }

    public boolean wasDisconnected() {
        return disconnected;
    }

    public Node destination() {
        return destination;
    }
    
    public RequestHeader requestHeader() {
        return requestHeader;
    }

    public AbstractResponse responseBody() {
        return responseBody;
    }

    public boolean hasResponse() {
        return responseBody != null;
    }

    public long requestLatencyMs() {
        return latencyMs;
    }

    public void onComplete() {
        if (callback != null) {
        	callback.onComplete(this);
        }
            
    }

    @Override
    public String toString() {
        return "ClientResponse(receivedTimeMs=" + receivedTimeMs +
               ", latencyMs=" +
               latencyMs +
               ", disconnected=" +
               disconnected +
               ", requestHeader=" +
               ", responseBody=" +
               responseBody +
               ")";
    }

}
