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

import org.oracle.okafka.common.protocol.ApiKeys;

public class FetchRequest extends AbstractRequest {
	
	public static class Builder extends AbstractRequest.Builder<FetchRequest> {
		
		private final String topic;
		private final long pollTimeoutMs;
		
		public Builder(String topic, long pollTimeoutMs) {
			super(ApiKeys.FETCH);
			this.topic = topic;
			this.pollTimeoutMs = pollTimeoutMs;
		}
		
		@Override
        public FetchRequest build() {
            return new FetchRequest(topic, pollTimeoutMs);
        }
		
		@Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=fetchRequest").
                append(", topics=").append(topic).
                append(")");
            return bld.toString();
        }
	}
	
	private final String topic;
	private final long pollTimeoutMs;
	private FetchRequest(String topic, long pollTimeoutMs) {
		this.topic = topic;
		this.pollTimeoutMs = pollTimeoutMs;
	}
	
	public String topic() {
		return this.topic;
	}
	
	public long pollTimeout() {
		return this.pollTimeoutMs;
	}
}
