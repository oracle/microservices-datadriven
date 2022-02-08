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

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.oracle.okafka.common.protocol.ApiKeys;

public class CreateTopicsRequest extends AbstractRequest {
    public static final class TopicDetails {
        public final int numPartitions;
        public final short replicationFactor;
        public final Map<Integer, List<Integer>> replicasAssignments;
        public final Map<String, String> configs;

        private TopicDetails(int numPartitions,
                             short replicationFactor,
                             Map<Integer, List<Integer>> replicasAssignments,
                             Map<String, String> configs) {
            this.numPartitions = numPartitions;
            this.replicationFactor = replicationFactor;
            this.replicasAssignments = replicasAssignments;
            this.configs = configs;
        }

        public TopicDetails(int partitions,
                            short replicationFactor,
                            Map<String, String> configs) {
            this(partitions, replicationFactor, Collections.<Integer, List<Integer>>emptyMap(), configs);
        }

        public TopicDetails(int partitions,
                            short replicationFactor) {
            this(partitions, replicationFactor, Collections.<String, String>emptyMap());
        }

        public TopicDetails(Map<Integer, List<Integer>> replicasAssignments,
                            Map<String, String> configs) {
            this(NO_NUM_PARTITIONS, NO_REPLICATION_FACTOR, replicasAssignments, configs);
        }

        public TopicDetails(Map<Integer, List<Integer>> replicasAssignments) {
            this(replicasAssignments, Collections.<String, String>emptyMap());
        }

        @Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(numPartitions=").append(numPartitions).
                    append(", replicationFactor=").append(replicationFactor).
                    append(", replicasAssignments=").append(replicasAssignments).
                    append(", configs=").append(configs).
                    append(")");
            return bld.toString();
        }
    }

    public static class Builder extends AbstractRequest.Builder<CreateTopicsRequest> {
        private final Map<String, TopicDetails> topics;
        private final int timeout;
        private final boolean validateOnly; // introduced in V1

        public Builder(Map<String, TopicDetails> topics, int timeout) {
            this(topics, timeout, false);
        }

        public Builder(Map<String, TopicDetails> topics, int timeout, boolean validateOnly) {
            super(ApiKeys.CREATE_TOPICS);
            this.topics = topics;
            this.timeout = timeout;
            this.validateOnly = validateOnly;
        }

        @Override
        public CreateTopicsRequest build() {
            return new CreateTopicsRequest(topics, timeout, validateOnly);
        }

        @Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=CreateTopicsRequest").
                append(", topics=").append(topics).
                append(", timeout=").append(timeout).
                append(", validateOnly=").append(validateOnly).
                append(")");
            return bld.toString();
        }
    }

    private final Map<String, TopicDetails> topics;
    private final Integer timeout;
    private final boolean validateOnly; // introduced in V1

    // Set to handle special case where 2 requests for the same topic exist on the wire.
    // This allows the broker to return an error code for these topics.
    private final Set<String> duplicateTopics;

    public static final int NO_NUM_PARTITIONS = -1;
    public static final short NO_REPLICATION_FACTOR = -1;

    private CreateTopicsRequest(Map<String, TopicDetails> topics, Integer timeout, boolean validateOnly) {
        this.topics = topics;
        this.timeout = timeout;
        this.validateOnly = validateOnly;
        this.duplicateTopics = Collections.emptySet();
    }

    public Map<String, TopicDetails> topics() {
        return this.topics;
    }

    public int timeout() {
        return this.timeout;
    }

    public boolean validateOnly() {
        return validateOnly;
    }

    public Set<String> duplicateTopics() {
        return this.duplicateTopics;
    }
}
