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

import java.util.Set;

import org.oracle.okafka.common.protocol.ApiKeys;
import org.oracle.okafka.common.utils.Utils;

public class DeleteTopicsRequest extends AbstractRequest {
   

    private final Set<String> topics;
    private final Integer timeout;

    public static class Builder extends AbstractRequest.Builder<DeleteTopicsRequest> {
        private final Set<String> topics;
        private final Integer timeout;

        public Builder(Set<String> topics, Integer timeout) {
            super(ApiKeys.DELETE_TOPICS);
            this.topics = topics;
            this.timeout = timeout;
        }

        @Override
        public DeleteTopicsRequest build() {
            return new DeleteTopicsRequest(topics, timeout);
        }

        @Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=DeleteTopicsRequest").
                append(", topics=(").append(Utils.join(topics, ", ")).append(")").
                append(", timeout=").append(timeout).
                append(")");
            return bld.toString();
        }
    }

    private DeleteTopicsRequest(Set<String> topics, Integer timeout) {
        this.topics = topics;
        this.timeout = timeout;
    }

    public Set<String> topics() {
        return topics;
    }

    public Integer timeout() {
        return this.timeout;
    }

}
