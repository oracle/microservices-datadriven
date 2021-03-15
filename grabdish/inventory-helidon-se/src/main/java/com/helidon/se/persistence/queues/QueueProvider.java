/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.queues;

public interface QueueProvider {

    String sendMessage(Object message, String owner, String queueName) throws Exception;

    String getMessage(String owner, String queueName) throws Exception;
}
