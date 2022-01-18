/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import java.util.List;
import java.util.Map;

import org.oracle.okafka.clients.consumer.OffsetAndMetadata;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.TopicPartition;

public class CommitResponse extends AbstractResponse {
	
	private final boolean error;
	private final Map<Node, Exception> result;
	private final Map<Node, List<TopicPartition>> nodes;
	private final Map<TopicPartition, OffsetAndMetadata> offsets;
	
	public CommitResponse(Map<Node, Exception> result, Map<Node, List<TopicPartition>> nodes,
			              Map<TopicPartition, OffsetAndMetadata> offsets, boolean error) {
		this.result = result;
		this.nodes = nodes;
		this.offsets = offsets;
		this.error = error;
		
	}
	
	public Map<Node, Exception> getResult() {
		return result;
	}
	
	public Map<Node, List<TopicPartition>> getNodes() {
		return nodes;
	}
	
	public Map<TopicPartition, OffsetAndMetadata> offsets() {
		return offsets;
	}
	
	public boolean error() {
		return error;
	}
	

}
