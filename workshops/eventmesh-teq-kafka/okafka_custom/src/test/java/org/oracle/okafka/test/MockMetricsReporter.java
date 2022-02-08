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

package org.oracle.okafka.test;

import org.oracle.okafka.common.metrics.KafkaMetric;
import org.oracle.okafka.common.metrics.MetricsReporter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

public class MockMetricsReporter implements MetricsReporter {
    public static final AtomicInteger INIT_COUNT = new AtomicInteger(0);
    public static final AtomicInteger CLOSE_COUNT = new AtomicInteger(0);

    public MockMetricsReporter() {
    }

    @Override
    public void init(List<KafkaMetric> metrics) {
        INIT_COUNT.incrementAndGet();
    }

    @Override
    public void metricChange(KafkaMetric metric) {}

    @Override
    public void metricRemoval(KafkaMetric metric) {}

    @Override
    public void close() {
        CLOSE_COUNT.incrementAndGet();
    }

    @Override
    public void configure(Map<String, ?> configs) {
    }
}