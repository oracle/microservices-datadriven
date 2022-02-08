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

package org.oracle.okafka.clients.producer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;


//import org.junit.jupiter.api.Test;
import org.junit.Test;
import org.oracle.okafka.clients.producer.internals.FutureRecordMetadata;
import org.oracle.okafka.clients.producer.internals.ProduceRequestResult;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.errors.CorruptRecordException;
import org.oracle.okafka.common.record.RecordBatch;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

//import static org.junit.jupiter.api.Assertions.*;


public class RecordSendTest {

    private final TopicPartition topicPartition = new TopicPartition("test", 0);
    private final long baseOffset = 0;
    private final int relOffset = 0;
    private final List<String> msgIds = Collections.singletonList("ID:00000000000000000000000000660000");
    private final List<Long> timeStamps = Collections.singletonList(RecordBatch.NO_TIMESTAMP);       

    /**
     * Test that waiting on a request that never completes times out
     */
    @Test
    public void testTimeout() throws Exception {
        ProduceRequestResult request = new ProduceRequestResult(topicPartition);
        FutureRecordMetadata future = new FutureRecordMetadata(request, relOffset,
                RecordBatch.NO_TIMESTAMP, 0L, 0, 0);

        assertFalse("Request is not completed", future.isDone());
        try {
            future.get(5, TimeUnit.MILLISECONDS);
            fail("Should have thrown exception.");
        } catch (TimeoutException e) { /* this is good */
        }
       
        
        request.set(msgIds, timeStamps, null);
        request.done();
        assertTrue(future.isDone());
        assertEquals((baseOffset << 16) + relOffset, future.get().offset());
    }

    /**
     * Test that an asynchronous request will eventually throw the right exception
     */
    //@Test(expected = ExecutionException.class)
    @Test
    public void testError() throws Exception {
        FutureRecordMetadata future = new FutureRecordMetadata(asyncRequest(msgIds, new CorruptRecordException(), 50L),
                relOffset, RecordBatch.NO_TIMESTAMP, 0L, 0, 0);
        future.get();
    }

    /**
     * Test that an asynchronous request will eventually return the right offset
     */
    @Test
    public void testBlocking() throws Exception {
        FutureRecordMetadata future = new FutureRecordMetadata(asyncRequest(msgIds, null, 50L),
                relOffset, RecordBatch.NO_TIMESTAMP, 0L, 0, 0);
        assertEquals((baseOffset << 16) + relOffset, future.get().offset());
    }

    /* create a new request result that will be completed after the given timeout */
    public ProduceRequestResult asyncRequest(final List<String> msgIds, final RuntimeException error, final long timeout) {
        final ProduceRequestResult request = new ProduceRequestResult(topicPartition);
        Thread thread = new Thread() {
            public void run() {
                try {
                    sleep(timeout);
                    request.set(msgIds, timeStamps, error);
                    request.done();
                } catch (InterruptedException e) { }
            }
        };
        thread.start();
        return request;
    }

}
