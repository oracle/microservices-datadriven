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
package org.oracle.okafka.clients.producer;

/**
 * A callback interface that the user can implement to allow code to execute when the request is complete. This callback
 * will generally execute in the background I/O thread so it should be fast.
 */
public interface Callback {

    /**
     * A callback method the user can implement to provide synchronous handling of request completion. This method will
     * be called when the record sent to the server has been acknowledged. Exactly one of the arguments will be
     * non-null.
     * @param metadata The metadata for the record that was sent (i.e. the partition and offset). Null if an error
     *        occurred.
     * @param exception The exception thrown during processing of this record. Null if no error occurred.
     *                  Possible thrown exceptions include:
     *                  org.oracle.okafka.common.errors.TimeoutException  thrown when a batch is expired.
     *                  javax.jms.JMSException thrown for any other exception.
     */
    public void onCompletion(RecordMetadata metadata, Exception exception);
}
