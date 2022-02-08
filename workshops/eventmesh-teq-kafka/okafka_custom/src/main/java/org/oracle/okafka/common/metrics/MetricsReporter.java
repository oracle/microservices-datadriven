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

package org.oracle.okafka.common.metrics;

import java.util.List;

import org.oracle.okafka.common.Configurable;

/**
 * A plugin interface to allow things to listen as new metrics are created so they can be reported.
 * <p>
 * Implement {@link org.oracle.okafka.common.ClusterResourceListener} to receive cluster metadata once it's available. Please see the class documentation for ClusterResourceListener for more information.
 */
public interface MetricsReporter extends Configurable {

    /**
     * This is called when the reporter is first registered to initially register all existing metrics
     * @param metrics All currently existing metrics
     */
    public void init(List<KafkaMetric> metrics);

    /**
     * This is called whenever a metric is updated or added
     * @param metric
     */
    public void metricChange(KafkaMetric metric);

    /**
     * This is called whenever a metric is removed
     * @param metric
     */
    public void metricRemoval(KafkaMetric metric);

    /**
     * Called when the metrics repository is closed.
     */
    public void close();

}
