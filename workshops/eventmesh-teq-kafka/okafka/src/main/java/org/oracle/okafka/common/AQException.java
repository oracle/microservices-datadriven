/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common;

/** 
 * Base class of all other TEQ exceptions.
 * 
 * @author srkarre
 *
 */
public class AQException extends RuntimeException {
	private final static long serialVersionUID = 1L;

    public AQException(String message, Throwable cause) {
        super(message, cause);
    }

    public AQException(String message) {
        super(message);
    }

    public AQException(Throwable cause) {
        super(cause);
    }

    public AQException() {
        super();
    }

}
