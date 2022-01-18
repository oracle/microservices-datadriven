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

import org.junit.Test;
import org.oracle.okafka.clients.producer.Callback;
import org.oracle.okafka.clients.producer.RecordMetadata;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.record.*;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;

import static org.junit.Assert.*;

public class ProducerBatchTest {

    private final long now = 1488748346917L;

    private final MemoryRecordsBuilder memoryRecordsBuilder = MemoryRecords.builder(ByteBuffer.allocate(128),
            CompressionType.NONE, TimestampType.CREATE_TIME, 128);

    @Test
    public void testChecksumNullForMagicV2() {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        FutureRecordMetadata future = batch.tryAppend(now, null, new byte[10], Record.EMPTY_HEADERS, null, now);
        assertNotNull(future);
        assertNull(future.checksumOrNull());
    }

    @Test
    public void testBatchAbort() throws Exception {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        MockCallback callback = new MockCallback();
        FutureRecordMetadata future = batch.tryAppend(now, null, new byte[10], Record.EMPTY_HEADERS, callback, now);

        KafkaException exception = new KafkaException();
        batch.abort(exception);
        assertTrue(future.isDone());
        assertEquals(1, callback.invocations);
        assertEquals(exception, callback.exception);
        assertNull(callback.metadata);

        // subsequent completion should be ignored
        assertFalse(batch.done(new ArrayList<String>() {{ add("ID:00000000000000000000000000660000"); } }, new ArrayList<Long>() { {add(2342342341L);} }, null));
        assertFalse(batch.done(new ArrayList<String>() {{ add("ID:00000000000000000000000000660000"); } }, new ArrayList<Long>() { {add(2342342341L);} }, new KafkaException()));
        assertEquals(1, callback.invocations);

        assertTrue(future.isDone());
        try {
            future.get();
            fail("Future should have thrown");
        } catch (ExecutionException e) {
            assertEquals(exception, e.getCause());
        }
    }

    @Test
    public void testBatchCannotAbortTwice() throws Exception {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        MockCallback callback = new MockCallback();
        FutureRecordMetadata future = batch.tryAppend(now, null, new byte[10], Record.EMPTY_HEADERS, callback, now);
        KafkaException exception = new KafkaException();
        batch.abort(exception);
        assertEquals(1, callback.invocations);
        assertEquals(exception, callback.exception);
        assertNull(callback.metadata);

        try {
            batch.abort(new KafkaException());
            fail("Expected exception from abort");
        } catch (IllegalStateException e) {
            // expected
        }

        assertEquals(1, callback.invocations);
        assertTrue(future.isDone());
        try {
            future.get();
            fail("Future should have thrown");
        } catch (ExecutionException e) {
            assertEquals(exception, e.getCause());
        }
    }

    @Test
    public void testBatchCannotCompleteTwice() throws Exception {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        MockCallback callback = new MockCallback();
        FutureRecordMetadata future = batch.tryAppend(now, null, new byte[10], Record.EMPTY_HEADERS, callback, now);
        batch.done(new ArrayList<String>() {{ add("ID:00000000000000000000000000660000"); } }, new ArrayList<Long>() { {add(10L);} }, null);
        assertEquals(1, callback.invocations);
        assertNull(callback.exception);
        assertNotNull(callback.metadata);

        try {
            batch.done(new ArrayList<String>() {{ add("ID:00000000000000000000000000660001"); } }, new ArrayList<Long>() { {add(20L);} }, null);
            fail("Expected exception from done");
        } catch (IllegalStateException e) {
            // expected
        }

        RecordMetadata recordMetadata = future.get();
        assertEquals(0L, recordMetadata.offset());
        assertEquals(10L, recordMetadata.timestamp());
    }

/*
    @Test
    public void testSplitPreservesHeaders() {
        for (CompressionType compressionType : CompressionType.values()) {
            MemoryRecordsBuilder builder = MemoryRecords.builder(
                    ByteBuffer.allocate(1024),
                    MAGIC_VALUE_V2,
                    compressionType,
                    TimestampType.CREATE_TIME,
                    0L);
            ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), builder, now);
            Header header = new RecordHeader("header-key", "header-value".getBytes());

            while (true) {
                FutureRecordMetadata future = batch.tryAppend(
                        now, "hi".getBytes(), "there".getBytes(),
                        new Header[]{header}, null, now);
                if (future == null) {
                    break;
                }
            }
            Deque<ProducerBatch> batches = batch.split(200);
            assertTrue("This batch should be split to multiple small batches.", batches.size() >= 2);

            for (ProducerBatch splitProducerBatch : batches) {
                for (RecordBatch splitBatch : splitProducerBatch.records().batches()) {
                    for (Record record : splitBatch) {
                        assertTrue("Header size should be 1.", record.headers().length == 1);
                        assertTrue("Header key should be 'header-key'.", record.headers()[0].key().equals("header-key"));
                        assertTrue("Header value should be 'header-value'.", new String(record.headers()[0].value()).equals("header-value"));
                    }
                }
            }
        }
    }

    @Test
    public void testSplitPreservesMagicAndCompressionType() {
        for (byte magic : Arrays.asList(MAGIC_VALUE_V0, MAGIC_VALUE_V1, MAGIC_VALUE_V2)) {
            for (CompressionType compressionType : CompressionType.values()) {
                if (compressionType == CompressionType.NONE && magic < MAGIC_VALUE_V2)
                    continue;

                MemoryRecordsBuilder builder = MemoryRecords.builder(ByteBuffer.allocate(1024), magic,
                        compressionType, TimestampType.CREATE_TIME, 0L);

                ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), builder, now);
                while (true) {
                    FutureRecordMetadata future = batch.tryAppend(now, "hi".getBytes(), "there".getBytes(),
                            Record.EMPTY_HEADERS, null, now);
                    if (future == null)
                        break;
                }

                Deque<ProducerBatch> batches = batch.split(512);
                assertTrue(batches.size() >= 2);

                for (ProducerBatch splitProducerBatch : batches) {
                    assertEquals(magic, splitProducerBatch.magic());
                    assertTrue(splitProducerBatch.isSplitBatch());

                    for (RecordBatch splitBatch : splitProducerBatch.records().batches()) {
                        assertEquals(magic, splitBatch.magic());
                        assertEquals(0L, splitBatch.baseOffset());
                        assertEquals(compressionType, splitBatch.compressionType());
                    }
                }
            }
        }
    }
*/
    /**
     * A {@link ProducerBatch} configured using a very large linger value and a timestamp preceding its create
     * time is interpreted correctly as not expired when the linger time is larger than the difference
     * between now and create time by {@link ProducerBatch#maybeExpire(int, long, long, long, boolean)}.
     */
    @Test
    public void testLargeLingerOldNowExpire() {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        // Set `now` to 2ms before the create time.
        assertFalse(batch.maybeExpire(10240, 100L, now - 2L, Long.MAX_VALUE, false));
    }

    /**
     * A {@link ProducerBatch} configured using a very large retryBackoff value with retry = true and a timestamp
     * preceding its create time is interpreted correctly as not expired when the retryBackoff time is larger than the
     * difference between now and create time by {@link ProducerBatch#maybeExpire(int, long, long, long, boolean)}.
     */
    @Test
    public void testLargeRetryBackoffOldNowExpire() {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        // Set batch.retry = true
        batch.reenqueued(now);
        // Set `now` to 2ms before the create time.
        assertFalse(batch.maybeExpire(10240, Long.MAX_VALUE, now - 2L, 10240L, false));
    }

    /**
     * A {@link ProducerBatch#maybeExpire(int, long, long, long, boolean)} call with a now value before the create
     * time of the ProducerBatch is correctly recognized as not expired when invoked with parameter isFull = true.
     */
    @Test
    public void testLargeFullOldNowExpire() {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        // Set `now` to 2ms before the create time.
        assertFalse(batch.maybeExpire(10240, 10240L, now - 2L, 10240L, true));
    }

    @Test
    public void testShouldNotAttemptAppendOnceRecordsBuilderIsClosedForAppends() {
        ProducerBatch batch = new ProducerBatch(new TopicPartition("topic", 1), memoryRecordsBuilder, now);
        FutureRecordMetadata result0 = batch.tryAppend(now, null, new byte[10], Record.EMPTY_HEADERS, null, now);
        assertNotNull(result0);
        assertTrue(memoryRecordsBuilder.hasRoomFor(now, null, new byte[10], Record.EMPTY_HEADERS));
        memoryRecordsBuilder.closeForRecordAppends();
        assertFalse(memoryRecordsBuilder.hasRoomFor(now, null, new byte[10], Record.EMPTY_HEADERS));
        assertEquals(null, batch.tryAppend(now + 1, null, new byte[10], Record.EMPTY_HEADERS, null, now + 1));
    }

    private static class MockCallback implements Callback {
        private int invocations = 0;
        private RecordMetadata metadata;
        private Exception exception;

        @Override
        public void onCompletion(RecordMetadata metadata, Exception exception) {
            invocations++;
            this.metadata = metadata;
            this.exception = exception;
        }
    }

}
