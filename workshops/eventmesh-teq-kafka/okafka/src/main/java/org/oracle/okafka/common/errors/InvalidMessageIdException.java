/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.errors;

import org.oracle.okafka.common.AQException;

/** 
 * This exception indicates  that client has received invalid message id from server.
 * 
 * @author srkarre
 *
 */
public class InvalidMessageIdException extends AQException {

	private static final long serialVersionUID = 1L;

    public InvalidMessageIdException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidMessageIdException(String message) {
        super(message);
    }

    public InvalidMessageIdException(Throwable cause) {
        super(cause);
    }

    public InvalidMessageIdException() {
        super();
    }
}
