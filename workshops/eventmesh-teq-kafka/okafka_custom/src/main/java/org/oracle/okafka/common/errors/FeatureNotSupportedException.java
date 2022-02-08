/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.errors;

import org.oracle.okafka.common.AQException;

/**
 * If a method/api is not supported then this exception is thrown.
 * 
 * @author srkarre
 *
 */
public class FeatureNotSupportedException extends AQException {
	private static final long serialVersionUID = 1L;

    public FeatureNotSupportedException(String message, Throwable cause) {
        super(message, cause);
    }

    public FeatureNotSupportedException(String message) {
        super(message);
    }

    public FeatureNotSupportedException(Throwable cause) {
        super(cause);
    }

    public FeatureNotSupportedException() {
        super();
    }

}
