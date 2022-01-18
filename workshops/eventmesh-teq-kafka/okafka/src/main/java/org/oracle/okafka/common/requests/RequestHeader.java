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

package org.oracle.okafka.common.requests;

import static java.util.Objects.requireNonNull;

import org.oracle.okafka.common.protocol.ApiKeys;

/**
 * The header for a request in the Kafka protocol
 */
public class RequestHeader {
 
    private final ApiKeys apiKey;
    private final String clientId;
    private final int correlationId;
    public RequestHeader(ApiKeys apiKey, String clientId, int correlation) {
        this.apiKey = requireNonNull(apiKey);
        this.clientId = clientId;
        this.correlationId = correlation;
    }
    public ApiKeys apiKey() {
        return apiKey;
    }

    public String clientId() {
        return clientId;
    }

    public int correlationId() {
        return correlationId;
    }

    public ResponseHeader toResponseHeader() {
        return new ResponseHeader(correlationId);
    }

    @Override
    public String toString() {
        return "RequestHeader(apiKey=" + apiKey +
                ", clientId=" + clientId +
                ", correlationId=" + correlationId +
                ")";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        RequestHeader that = (RequestHeader) o;
        return apiKey == that.apiKey &&
                correlationId == that.correlationId &&
                (clientId == null ? that.clientId == null : clientId.equals(that.clientId));
    }

    @Override
    public int hashCode() {
        int result = apiKey.hashCode();
        result = 31 * result + (clientId != null ? clientId.hashCode() : 0);
        result = 31 * result + correlationId;
        return result;
    }
}
