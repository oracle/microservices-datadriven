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

import java.util.HashSet;
import java.util.List;
import java.util.Map;

import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.PartitionInfo;
import org.oracle.okafka.common.config.AbstractConfig;

public class MetadataResponse extends AbstractResponse {
	private final String clusterId = "";
	private final List<Node> nodes;
	private final List<PartitionInfo> partitionInfo;
	private final Map<String, Exception> errorsPerTopic;
	
	public MetadataResponse(List<Node> nodes, List<PartitionInfo> partitionInfo, Map<String, Exception> errorsPerTopic) {
		this.nodes = nodes;
		this.partitionInfo = partitionInfo;
		this.errorsPerTopic = errorsPerTopic;
	}
	
	public List<Node> nodes() {
		return nodes;
	}
	
	public List<PartitionInfo> partitions() {
		return partitionInfo;
	}
	
	/**
     * Get a snapshot of the cluster metadata from this response
     * @return the cluster snapshot
     */
    public Cluster cluster(AbstractConfig configs) {
    	return new Cluster(clusterId, nodes, partitionInfo,new HashSet<>(), new HashSet<>(), nodes.size() > 0 ?nodes.get(0) : null, configs);
    }
    
    public Map<String, Exception> topicErrors() {
    	return  this.errorsPerTopic;
    }
}
