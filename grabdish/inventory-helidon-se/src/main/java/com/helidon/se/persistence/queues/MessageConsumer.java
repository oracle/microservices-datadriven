/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.queues;

import com.helidon.se.persistence.context.DBContext;

public interface MessageConsumer {

    void accept(DBContext context, String message) throws Exception;
}
