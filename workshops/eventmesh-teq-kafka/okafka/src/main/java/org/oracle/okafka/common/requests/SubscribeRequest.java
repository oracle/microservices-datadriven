/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import org.oracle.okafka.common.protocol.ApiKeys;

public class SubscribeRequest extends AbstractRequest {
public static class Builder extends AbstractRequest.Builder<SubscribeRequest> {
		private final String topic;
		public Builder(String topic) {
			super(ApiKeys.SUBSCRIBE);
			this.topic = topic;
		}
		
		@Override
        public SubscribeRequest build() {
            return new SubscribeRequest(topic);
        }
		
		@Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=subscribeRequest").
            append(", topics=").append(topic).
                append(")");
            return bld.toString();
        }
	}
    private final String topic;
    public SubscribeRequest(String topic) {
	    this.topic = topic;
    }

    public String getTopic() {
    	return this.topic;
    }

}

