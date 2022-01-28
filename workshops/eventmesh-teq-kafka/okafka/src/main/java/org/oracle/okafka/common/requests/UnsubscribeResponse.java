/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.requests;

import java.util.Map;

public class UnsubscribeResponse extends AbstractResponse {
	private final Map<String, Exception> response;
	
	public UnsubscribeResponse(Map<String, Exception> response) {
		this.response = response;
	}
	
	public Map<String, Exception> response() {
		return this.response;
		
	}

}

