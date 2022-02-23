/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * 04/20/2020: This file is modified to support Kafka Java Client compatability to Oracle Transactional Event Queues.
 *
 */

package org.oracle.okafka.clients.producer.internals;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.oracle.okafka.clients.producer.RecordMetadata;
import org.oracle.okafka.common.utils.MessageIdConverter;

/**
 * The future result of a record send
 */
public final class FutureRecordMetadata implements Future<RecordMetadata> {

    private final ProduceRequestResult result;
    private final int relativeOffset;
    private final long createTimestamp;
    private final Long checksum;
    private final int serializedKeySize;
    private final int serializedValueSize;
    private volatile FutureRecordMetadata nextRecordMetadata = null;

    public FutureRecordMetadata(ProduceRequestResult result, int relativeOffset, long createTimestamp,
                                Long checksum, int serializedKeySize, int serializedValueSize) {
        this.result = result;
        this.relativeOffset = relativeOffset;
        this.createTimestamp = createTimestamp;
        this.checksum = checksum;
        this.serializedKeySize = serializedKeySize;
        this.serializedValueSize = serializedValueSize;
    }

    @Override
    public boolean cancel(boolean interrupt) {
        return false;
    }

    @Override
    public boolean isCancelled() {
        return false;
    }

    @Override
    public RecordMetadata get() throws InterruptedException, ExecutionException {
        this.result.await();
        if (nextRecordMetadata != null)
            return nextRecordMetadata.get();
        return valueOrError();
    }

    @Override
    public RecordMetadata get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException {
        // Handle overflow.
        long now = System.currentTimeMillis();
        long deadline = Long.MAX_VALUE - timeout < now ? Long.MAX_VALUE : now + timeout;
        boolean occurred = this.result.await(timeout, unit);
        if (nextRecordMetadata != null)
            return nextRecordMetadata.get(deadline - System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        if (!occurred)
            throw new TimeoutException("Timeout after waiting for " + TimeUnit.MILLISECONDS.convert(timeout, unit) + " ms.");
        return valueOrError();
    }

    /**
     * This method is used when we have to split a large batch in smaller ones. A chained metadata will allow the
     * future that has already returned to the users to wait on the newly created split batches even after the
     * old big batch has been deemed as done.
     */
    void chain(FutureRecordMetadata futureRecordMetadata) {
        if (nextRecordMetadata == null)
            nextRecordMetadata = futureRecordMetadata;
        else
            nextRecordMetadata.chain(futureRecordMetadata);
    }

    RecordMetadata valueOrError() throws ExecutionException {
        if (this.result.error() != null)
            throw new ExecutionException(this.result.error());
        else
            return value();
    }

    Long checksumOrNull() {
        return this.checksum;
    }

    /**
     * Converts TEQ message id into kafka offset
     * @return record metadata
     */
    RecordMetadata value() {
        if (nextRecordMetadata != null)
            return nextRecordMetadata.value();
        long baseOffset = -1;
        long relOffset = -1;
        if(this.result.msgIds() != null) {
        	try {
        		
        		String msgId = this.result.msgIds().get(relativeOffset); 
            	long offset = MessageIdConverter.getOffset(msgId);    
            	
            	baseOffset = offset >>> 16;
            	relOffset = offset & 65535;
        	} catch(RuntimeException exception) {
        		baseOffset = -1;
        		relOffset = -1;
        	} 
        } 
        return new RecordMetadata(result.topicPartition(), baseOffset, relOffset,
                                  timestamp(), this.checksum, this.serializedKeySize, this.serializedValueSize);
    }

    private long timestamp() {
        return result.hasLogAppendTime() ? result.logAppendTime().get(relativeOffset) : createTimestamp;
    }

    @Override
    public boolean isDone() {
        if (nextRecordMetadata != null)
            return nextRecordMetadata.isDone();
        return this.result.completed();
    }

}
