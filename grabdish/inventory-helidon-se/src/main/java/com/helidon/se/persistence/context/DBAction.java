/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.context;

import oracle.jdbc.OracleConnection;

public interface DBAction<T> {

    T accept(OracleConnection commection) throws Exception;
}
