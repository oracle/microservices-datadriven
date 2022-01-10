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
import org.oracle.okafka.common.protocol.ApiKeys;

public class CommitRequest extends AbstractRequest {
public static class Builder extends AbstractRequest.Builder<CommitRequest> {
		
		private final Map<Node, List<TopicPartition>> nodes;
		private final Map<TopicPartition, OffsetAndMetadata> offsetAndMetadata;
		
		public Builder(Map<Node, List<TopicPartition>> nodes, Map<TopicPartition, OffsetAndMetadata> offsetAndMetadata) {
			super(ApiKeys.COMMIT);
			this.nodes = nodes;
			this.offsetAndMetadata = offsetAndMetadata;
		}
		
		@Override
        public CommitRequest build() {
            return new CommitRequest(nodes, offsetAndMetadata);
        }
		
		@Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=commitRequest").
                append(")");
            return bld.toString();
        }
	}
	
private final Map<Node, List<TopicPartition>> nodes;
private final Map<TopicPartition, OffsetAndMetadata> offsetAndMetadata;
	private CommitRequest(Map<Node, List<TopicPartition>> nodes, Map<TopicPartition, OffsetAndMetadata> offsetAndMetadata) {
		this.nodes = nodes;
		this.offsetAndMetadata = offsetAndMetadata;
	}
	
	public Map<Node, List<TopicPartition>> nodes() {
		return this.nodes;
	}
	
	public Map<TopicPartition, OffsetAndMetadata> offsets() {
		return this.offsetAndMetadata;
	}


}
