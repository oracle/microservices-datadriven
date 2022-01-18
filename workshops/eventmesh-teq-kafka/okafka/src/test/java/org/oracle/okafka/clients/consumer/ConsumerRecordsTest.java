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
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.record.TimestampType;

import java.util.*;

import static org.junit.Assert.assertEquals;

public class ConsumerRecordsTest {

    @Test
    public void iterator() throws Exception {

        Map<TopicPartition, List<ConsumerRecord<Integer, String>>> records = new LinkedHashMap<>();

        String topic = "topic";
        records.put(new TopicPartition(topic, 0), new ArrayList<ConsumerRecord<Integer, String>>());
        ConsumerRecord<Integer, String> record1 = new ConsumerRecord<>(topic, 1, 0, 0L, TimestampType.CREATE_TIME, 0L, 0, 0, 1, "value1");
        ConsumerRecord<Integer, String> record2 = new ConsumerRecord<>(topic, 1, 1, 0L, TimestampType.CREATE_TIME, 0L, 0, 0, 2, "value2");
        records.put(new TopicPartition(topic, 1), Arrays.asList(record1, record2));
        records.put(new TopicPartition(topic, 2), new ArrayList<ConsumerRecord<Integer, String>>());

        ConsumerRecords<Integer, String> consumerRecords = new ConsumerRecords<>(records);
        Iterator<ConsumerRecord<Integer, String>> iter = consumerRecords.iterator();

        int c = 0;
        for (; iter.hasNext(); c++) {
            ConsumerRecord<Integer, String> record = iter.next();
            assertEquals(1, record.partition());
            assertEquals(topic, record.topic());
            assertEquals(c, record.offset());
        }
        assertEquals(2, c);
    }
}
