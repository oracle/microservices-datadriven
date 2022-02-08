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
package org.oracle.okafka.clients.consumer;

import java.util.Map;

import org.oracle.okafka.common.TopicPartition;

/**
 * A callback interface that the user can implement to trigger custom actions when a commit request completes. The callback
 * may be executed in any thread calling {@link Consumer#poll(java.time.Duration) poll()}.
 */
public interface OffsetCommitCallback {

    /**
     * A callback method the user can implement to provide asynchronous handling of commit request completion.
     * This method will be called when the commit request sent to the server has been acknowledged.
     *
     * @param offsets A map of the offsets and associated metadata that this callback applies to
     * @param exception The exception thrown during processing of the request, or null if the commit completed successfully
     * @throws org.oracle.okafka.common.KafkaException for any other unrecoverable errors (e.g. if offset metadata
     *             is too large or if the committed offset is invalid).
     */
    void onComplete(Map<TopicPartition, OffsetAndMetadata> offsets, Exception exception);
}
