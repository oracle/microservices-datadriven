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

package org.oracle.okafka.clients.admin;

import java.util.Collection;

import org.oracle.okafka.common.KafkaFuture;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.annotation.InterfaceStability;

/**
 * The result of the {@link KafkaAdminClient#describeCluster()} call.
 *
 * The API of this class is evolving, see {@link AdminClient} for details.
 */
@InterfaceStability.Evolving
public class DescribeClusterResult {
    private final KafkaFuture<Collection<Node>> nodes;
    private final KafkaFuture<Node> controller;
    private final KafkaFuture<String> clusterId;

    DescribeClusterResult(KafkaFuture<Collection<Node>> nodes,
                          KafkaFuture<Node> controller,
                          KafkaFuture<String> clusterId) {
        this.nodes = nodes;
        this.controller = controller;
        this.clusterId = clusterId;
    }

    /**
     * Returns a future which yields a collection of nodes.
     */
    public KafkaFuture<Collection<Node>> nodes() {
        return nodes;
    }

    /**
     * Returns a future which yields the current controller id.
     * Note that this may yield null, if the controller ID is not yet known.
     */
    public KafkaFuture<Node> controller() {
        return controller;
    }

    /**
     * Returns a future which yields the current cluster id. The future value will be non-null if the
     * broker version is 0.10.1.0 or higher and null otherwise.
     */
    public KafkaFuture<String> clusterId() {
        return clusterId;
    }
}
