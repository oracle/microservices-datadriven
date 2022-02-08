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

package org.oracle.okafka.common.internals;

import java.util.ArrayList;
import java.util.List;

import org.oracle.okafka.common.ClusterResource;
import org.oracle.okafka.common.ClusterResourceListener;

public class ClusterResourceListeners {

    private final List<ClusterResourceListener> clusterResourceListeners;

    public ClusterResourceListeners() {
        this.clusterResourceListeners = new ArrayList<>();
    }

    /**
     * Add only if the candidate implements {@link ClusterResourceListener}.
     * @param candidate Object which might implement {@link ClusterResourceListener}
     */
    public void maybeAdd(Object candidate) {
        if (candidate instanceof ClusterResourceListener) {
            clusterResourceListeners.add((ClusterResourceListener) candidate);
        }
    }

    /**
     * Add all items who implement {@link ClusterResourceListener} from the list.
     * @param candidateList List of objects which might implement {@link ClusterResourceListener}
     */
    public void maybeAddAll(List<?> candidateList) {
        for (Object candidate : candidateList) {
            this.maybeAdd(candidate);
        }
    }

    /**
     * Send the updated cluster metadata to all {@link ClusterResourceListener}.
     * @param cluster Cluster metadata
     */
    public void onUpdate(ClusterResource cluster) {
        for (ClusterResourceListener clusterResourceListener : clusterResourceListeners) {
            clusterResourceListener.onUpdate(cluster);
        }
    }
}