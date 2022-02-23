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

package org.oracle.okafka.common.utils;

import java.io.*;

public class Serializer {

    public static byte[] serialize(Object toSerialize) throws IOException {
        ByteArrayOutputStream arrayOutputStream = new ByteArrayOutputStream();
        try (ObjectOutputStream ooStream = new ObjectOutputStream(arrayOutputStream)) {
            ooStream.writeObject(toSerialize);
            return arrayOutputStream.toByteArray();
        }
    }

    public static Object deserialize(InputStream inputStream) throws IOException, ClassNotFoundException {
        try (ObjectInputStream objectInputStream = new ObjectInputStream(inputStream)) {
            return objectInputStream.readObject();
        }
    }

    public static Object deserialize(byte[] byteArray) throws IOException, ClassNotFoundException {
        ByteArrayInputStream arrayInputStream = new ByteArrayInputStream(byteArray);
        return deserialize(arrayInputStream);
    }

    public static Object deserialize(String fileName) throws IOException, ClassNotFoundException {
        ClassLoader classLoader = Serializer.class.getClassLoader();
        InputStream fileStream = classLoader.getResourceAsStream(fileName);
        return deserialize(fileStream);
    }
}
