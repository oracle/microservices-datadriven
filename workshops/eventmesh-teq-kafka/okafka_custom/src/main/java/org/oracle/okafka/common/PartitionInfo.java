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

package org.oracle.okafka.common;

/**
 * This is used to describe per-partition state in the MetadataResponse.
 */
public class PartitionInfo {

    private final String topic;
    private final int partition;
    private final Node leader;

    public PartitionInfo(String topic, int partition, Node leader, Node[] replicas, Node[] inSyncReplicas) {
        this(topic, partition, leader, replicas, inSyncReplicas, new Node[0]);
    }

    public PartitionInfo(String topic, int partition, Node leader, Node[] replicas, Node[] inSyncReplicas, Node[] offlineReplicas) {
        this.topic = topic;
        this.partition = partition;
        this.leader = leader;
    }

    /**
     * The topic name
     */
    public String topic() {
        return topic;
    }

    /**
     * The partition id
     */
    public int partition() {
        return partition;
    }

    /**
     * The Node currently acting as a leader for this partition or null if there is no leader
     */
    public Node leader() {
        return leader;
    }

    /**
     * All oracle db instances run on same disk, so there is no need of replicating data among instances.
     * @return null since there is no replication.
     */
    public Node[] replicas() {
        return null;
    }

    /**
     * All oracle db instances run on same disk, so there is no need of replicating data among instances.
     * @return null since there is no replication.
     */
    public Node[] inSyncReplicas() {
        return null;
    }

    /**
     * All oracle db instances run on same disk, so there is no need of replicating data among instances.
     * @return null since there is no replication.
     */
    public Node[] offlineReplicas() {
        return null;
    }

    @Override
    public String toString() {
        return String.format("Partition(topic = %s, partition = %d, leader = %s)",
                             topic,
                             partition,
                             leader == null ? "none" : leader.idString() );

    }

}
