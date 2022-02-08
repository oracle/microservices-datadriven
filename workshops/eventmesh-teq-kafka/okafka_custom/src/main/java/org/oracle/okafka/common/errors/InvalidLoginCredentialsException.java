/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/


package org.oracle.okafka.common.errors;

import org.oracle.okafka.common.AQException;

/** 
 * This exception indicates that user provided invalid login details.
 * 
 * @author srkarre
 *
 */
public class InvalidLoginCredentialsException extends AQException {
	private final static long serialVersionUID = 1L;

    public InvalidLoginCredentialsException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidLoginCredentialsException(String message) {
        super(message);
    }

    public InvalidLoginCredentialsException(Throwable cause) {
        super(cause);
    }

    public InvalidLoginCredentialsException() {
        super();
    }

}
