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
 *    http://www.oracle.oorg/licenses/LICENSE-2.0
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

import org.junit.Test;
import org.oracle.okafka.common.header.internals.RecordHeaders;
import org.oracle.okafka.common.record.TimestampType;

import static org.junit.Assert.assertEquals;

public class ConsumerRecordTest {

    @Test
    @SuppressWarnings("deprecation")
    public void testOldConstructor() {
        String topic = "topic";
        int partition = 0;
        long offset = 23;
        String key = "key";
        String value = "value";

        ConsumerRecord<String, String> record = new ConsumerRecord<>(topic, partition, offset, key, value);
        assertEquals(topic, record.topic());
        assertEquals(partition, record.partition());
        assertEquals(offset, record.offset());
        assertEquals(key, record.key());
        assertEquals(value, record.value());
        assertEquals(TimestampType.NO_TIMESTAMP_TYPE, record.timestampType());
        assertEquals(ConsumerRecord.NO_TIMESTAMP, record.timestamp());
        assertEquals(ConsumerRecord.NULL_CHECKSUM, record.checksum());
        assertEquals(ConsumerRecord.NULL_SIZE, record.serializedKeySize());
        assertEquals(ConsumerRecord.NULL_SIZE, record.serializedValueSize());
        assertEquals(new RecordHeaders(), record.headers());
    }

}
