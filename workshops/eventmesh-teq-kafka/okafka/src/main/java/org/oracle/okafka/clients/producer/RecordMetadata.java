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

import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.record.RecordBatch;

/**
 * The metadata for a record that has been acknowledged by the server
 */
public final class RecordMetadata {

    /**
     * Partition value for record without partition assigned
     */
    public static final int UNKNOWN_PARTITION = -1;

    private final long offset;
    // The timestamp of the message.
    // If LogAppendTime is used for the topic, the timestamp will be the timestamp returned by the broker.
    // If CreateTime is used for the topic, the timestamp is the timestamp in the corresponding ProducerRecord if the
    // user provided one. Otherwise, it will be the producer local time when the producer record was handed to the
    // producer.
    private final long timestamp;
    private final int serializedKeySize;
    private final int serializedValueSize;
    private final TopicPartition topicPartition;

    private volatile Long checksum;

    public RecordMetadata(TopicPartition topicPartition, long baseOffset, long relativeOffset, long timestamp,
                          Long checksum, int serializedKeySize, int serializedValueSize) {
        // ignore the relativeOffset if the base offset is -1,
        // since this indicates the offset is unknown
        this.offset = baseOffset == -1 ? -1 :((baseOffset << 16) + (relativeOffset));
        this.timestamp = timestamp;
        this.checksum = checksum;
        this.serializedKeySize = serializedKeySize;
        this.serializedValueSize = serializedValueSize;
        this.topicPartition = topicPartition;
    }

    /**
     * Indicates whether the record metadata includes the offset.
     * @return true if the offset is included in the metadata, false otherwise.
     */
    public boolean hasOffset() {
        return this.offset != -1L;
    }

    /**
     * The offset of the record in the topic/partition.
     * @return the offset of the record, or -1 if {{@link #hasOffset()}} returns false.
     */
    public long offset() {
        return this.offset;
    }

    /**
     * Indicates whether the record metadata includes the timestamp.
     * @return true if a valid timestamp exists, false otherwise.
     */
    public boolean hasTimestamp() {
        return this.timestamp != RecordBatch.NO_TIMESTAMP;
    }

    /**
     * The timestamp of the record in the topic/partition.
     * This method returns <code>LogAppendTime</code> of the record. <code>CreateTime</code> of the record is not yet supported.
     * @return the timestamp of the record, or -1 if the {{@link #hasTimestamp()}} returns false.
     */
    public long timestamp() {
        return this.timestamp;
    }

    /**
     * This method is not yet supported.
     */
    @Deprecated
    public long checksum() {
    	return -1;
    }

    /**
     * The size of the serialized, uncompressed key in bytes. If key is null, the returned size
     * is -1.
     */
    public int serializedKeySize() {
        return this.serializedKeySize;
    }

    /**
     * The size of the serialized, uncompressed value in bytes. If value is null, the returned
     * size is -1.
     */
    public int serializedValueSize() {
        return this.serializedValueSize;
    }

    /**
     * The topic the record was appended to
     */
    public String topic() {
        return this.topicPartition.topic();
    }

    /**
     * The partition the record was sent to
     */
    public int partition() {
        return this.topicPartition.partition();
    }

    /**
     * @return  a string representing RecordMetadata object
     */
    @Override
    public String toString() {
        return topicPartition.toString() + "@" + offset;
    }
}
