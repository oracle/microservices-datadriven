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
 * Enum removed: CHECKING_API_VERSIONS
 */

package org.oracle.okafka.clients;

/**
 * The states of a node connection
 *
 * DISCONNECTED: connection has not been successfully established yet
 * CONNECTING: connection is under progress
 * READY: connection is ready to send requests
 * AUTHENTICATION_FAILED: connection failed due to an authentication error
 */
public enum ConnectionState {
    DISCONNECTED, CONNECTING, READY, AUTHENTICATION_FAILED;

    public boolean isDisconnected() {
        return this == AUTHENTICATION_FAILED || this == DISCONNECTED;
    }

    public boolean isConnected() {
        return this == READY;
    }
}
