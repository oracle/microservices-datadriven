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
package org.oracle.okafka.clients.producer.internals;

import static org.oracle.okafka.common.record.RecordBatch.NO_PRODUCER_EPOCH;
import static org.oracle.okafka.common.record.RecordBatch.NO_PRODUCER_ID;

class ProducerIdAndEpoch {
    static final ProducerIdAndEpoch NONE = new ProducerIdAndEpoch(NO_PRODUCER_ID, NO_PRODUCER_EPOCH);

    public final long producerId;
    public final short epoch;

    ProducerIdAndEpoch(long producerId, short epoch) {
        this.producerId = producerId;
        this.epoch = epoch;
    }

    public boolean isValid() {
        return NO_PRODUCER_ID < producerId;
    }

    @Override
    public String toString() {
        return "(producerId=" + producerId + ", epoch=" + epoch + ")";
    }
}
