/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import java.util.Map;

import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.protocol.ApiKeys;

public class OffsetResetRequest extends AbstractRequest {
	
	public static class Builder extends AbstractRequest.Builder<OffsetResetRequest> {
		
		private final Map<TopicPartition, Long> offsetResetTimestamps;
		private final long pollTimeoutMs;
		
		public Builder(Map<TopicPartition, Long> offsetResetTimestamps, long pollTimeoutMs) {
			super(ApiKeys.OFFSETRESET);
			this.offsetResetTimestamps = offsetResetTimestamps;
			this.pollTimeoutMs = pollTimeoutMs;
		}
		
		@Override
        public OffsetResetRequest build() {
            return new OffsetResetRequest(offsetResetTimestamps, pollTimeoutMs);
        }
		
		@Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=OffsetResetRequest").
                append(", offsetResetTimestampss=").append(offsetResetTimestamps).
                append(")");
            return bld.toString();
        }
	}
	
	private final Map<TopicPartition, Long> offsetResetTimestamps;
	private final long pollTimeoutMs;
	private OffsetResetRequest(Map<TopicPartition, Long> offsetResetTimestamps, long pollTimeoutMs) {
		this.offsetResetTimestamps = offsetResetTimestamps;
		this.pollTimeoutMs = pollTimeoutMs;
	}
	
	public Map<TopicPartition, Long> offsetResetTimestamps() {
		return this.offsetResetTimestamps;
	}
	
	public long pollTimeout() {
		return this.pollTimeoutMs;
	}
}
