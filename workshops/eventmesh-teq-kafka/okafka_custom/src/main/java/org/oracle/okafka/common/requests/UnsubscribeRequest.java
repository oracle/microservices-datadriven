/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import org.oracle.okafka.common.protocol.ApiKeys;

public class UnsubscribeRequest extends AbstractRequest {
public static class Builder extends AbstractRequest.Builder<UnsubscribeRequest> {
		
		public Builder() {
			super(ApiKeys.UNSUBSCRIBE);
		}
		
		@Override
        public UnsubscribeRequest build() {
            return new UnsubscribeRequest();
        }
		
		@Override
        public String toString() {
            StringBuilder bld = new StringBuilder();
            bld.append("(type=unsubscribeRequest").
                append(")");
            return bld.toString();
        }
	}
    public UnsubscribeRequest() {
    }

}
