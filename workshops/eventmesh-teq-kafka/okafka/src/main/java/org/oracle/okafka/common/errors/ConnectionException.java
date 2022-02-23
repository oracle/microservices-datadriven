/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.errors;

import org.oracle.okafka.common.KafkaException;

public class ConnectionException extends KafkaException {
	private static final long serialVersionUID = 1L;

	public ConnectionException(Throwable cause) {
		super(cause);
	}
	public ConnectionException(String msg) {
		super(msg);
	}
	
	public ConnectionException(String msg, Throwable cause) {
		super(msg, cause);
	}
	
	public ConnectionException() {
		super();
	}
 }
