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

package org.oracle.okafka.clients.consumer;

import org.oracle.okafka.common.header.Headers;
import org.oracle.okafka.common.header.internals.RecordHeaders;
import org.oracle.okafka.common.record.RecordBatch;
import org.oracle.okafka.common.record.TimestampType;

/**
 * A key/value pair to be received from TEQ. This also consists of a topic name and 
 * a partition number from which the record is being received, an offset that points 
 * to the record in a TEQ partition, and a timestamp as marked by the corresponding ProducerRecord. 
 * In TEQ message id uniquely identifies a record, this msgid is converted to kafka equivalent offset.
 */
public class ConsumerRecord<K, V> {
    public static final long NO_TIMESTAMP = RecordBatch.NO_TIMESTAMP;
    public static final int NULL_SIZE = -1;
    public static final int NULL_CHECKSUM = -1;

    private final String topic;
    private final int partition;
    private final long offset;
    private final long timestamp;
    private final TimestampType timestampType;
    private final int serializedKeySize;
    private final int serializedValueSize;
    private final Headers headers;
    private final K key;
    private final V value;

    private volatile Long checksum;

    /**
     * Creates a record to be received from a specified topic and partition (
     *
     * @param topic The topic this record is received from
     * @param partition The partition of the topic this record is received from
     * @param offset The offset of this record in the corresponding TEQ partition
     * @param key The key of the record, if one exists (null is allowed)
     * @param value The record contents
     */
    public ConsumerRecord(String topic,
                          int partition,
                          long offset,
                          K key,
                          V value) {
        this(topic, partition, offset, NO_TIMESTAMP, TimestampType.NO_TIMESTAMP_TYPE,
                NULL_CHECKSUM, NULL_SIZE, NULL_SIZE, key, value);
    }

    /**
     * Creates a record to be received from a specified topic and partition 
     *
     * @param topic The topic this record is received from
     * @param partition The partition of the topic this record is received from
     * @param offset The offset of this record in the corresponding TEQ partition
     * @param timestamp The timestamp of the record.
     * @param timestampType The timestamp type. LogAppendTime is the  default and only supported type.
     * @param checksum The checksum (CRC32) of the full record
     * @param serializedKeySize The length of the serialized key
     * @param serializedValueSize The length of the serialized value
     * @param key The key of the record, if one exists (null is allowed)
     * @param value The record contents
     */
    public ConsumerRecord(String topic,
                          int partition,
                          long offset,
                          long timestamp,
                          TimestampType timestampType,
                          long checksum,
                          int serializedKeySize,
                          int serializedValueSize,
                          K key,
                          V value) {
        this(topic, partition, offset, timestamp, timestampType, checksum, serializedKeySize, serializedValueSize,
                key, value, new RecordHeaders());
    }

    /**
     * Creates a record to be received from a specified topic and partition
     *
     * @param topic The topic this record is received from
     * @param partition The partition of the topic this record is received from
     * @param offset The offset of this record in the corresponding TEQ partition
     * @param timestamp The timestamp of the record.
     * @param timestampType The timestamp type. LogAppendTime is the  default and only supported type.
     * @param checksum The checksum (CRC32) of the full record
     * @param serializedKeySize The length of the serialized key
     * @param serializedValueSize The length of the serialized value
     * @param key The key of the record, if one exists (null is allowed)
     * @param value The record contents
     * @param headers The headers of the record.
     */
    public ConsumerRecord(String topic,
                          int partition,
                          long offset,
                          long timestamp,
                          TimestampType timestampType,
                          Long checksum,
                          int serializedKeySize,
                          int serializedValueSize,
                          K key,
                          V value,
                          Headers headers) {
        if (topic == null)
            throw new IllegalArgumentException("Topic cannot be null");
        this.topic = topic;
        this.partition = partition;
        this.offset = offset;
        this.timestamp = timestamp;
        this.timestampType = timestampType;
        this.checksum = checksum;
        this.serializedKeySize = serializedKeySize;
        this.serializedValueSize = serializedValueSize;
        this.key = key;
        this.value = value;
        this.headers = headers;
    }

    /**
     * The topic this record is received from
     */
    public String topic() {
        return this.topic;
    }

    /**
     * The partition from which this record is received
     */
    public int partition() {
        return this.partition;
    }

    /**
     * The headers
     */
    public Headers headers() {
        return headers;
    }
    
    /**
     * The key (or null if no key is specified)
     */
    public K key() {
        return key;
    }

    /**
     * The value
     */
    public V value() {
        return value;
    }

    /**
     * The position of this record in the corresponding TEQ partition. Returns msgid in the form of kafka equivalent offset.
     */
    public long offset() {
        return offset;
    }

    /**
     * The timestamp of this record
     */
    public long timestamp() {
        return timestamp;
    }

    /**
     * The timestamp type of this record
     */
    public TimestampType timestampType() {
        return timestampType;
    }

    /**
     *  This method is not yet supported.
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
     * The size of the serialized, uncompressed value in bytes. If value is null, the
     * returned size is -1.
     */
    public int serializedValueSize() {
        return this.serializedValueSize;
    }

    @Override
    public String toString() {
        return "ConsumerRecord(topic = " + topic() + ", partition = " + partition() + ", offset = " + offset()
               + ", " + timestampType + " = " + timestamp
               + ", serialized key size = "  + serializedKeySize
               + ", serialized value size = " + serializedValueSize
               + ", headers = " + headers
               + ", key = " + key + ", value = " + value + ")";
    }
}
