/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import javax.jms.JMSException;

public class SubscribeResponse extends AbstractResponse {
    private final JMSException exception;
	private final String topic;
	
	public SubscribeResponse(String topic, JMSException exception) {
		this.topic = topic;
		this.exception = exception;
	}
	
	public String getTopic() {
		return this.topic;
		
	}
	
	public JMSException getException() {
		return this.exception;
	}

}
