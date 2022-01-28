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

import org.oracle.okafka.clients.consumer.OffsetAndMetadata;
import org.oracle.okafka.common.Metric;
import org.oracle.okafka.common.MetricName;
import org.oracle.okafka.common.PartitionInfo;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.errors.ProducerFencedException;

import java.io.Closeable;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

/**
 * The interface for the {@link KafkaProducer}
 * @see KafkaProducer
 */
public interface Producer<K, V> extends Closeable {   
	
	/**
	 * See {@link KafkaProducer#initTransactions()}
	 */
	void initTransactions();
	
	/**
	 * See {@link KafkaProducer#beginTransaction()}
	 */
	void beginTransaction() throws ProducerFencedException;
	
	/**
	 * See {@link KafkaProducer#sendOffsetsToTransaction(Map, String)}
	 */
	void sendOffsetsToTransaction(Map<TopicPartition, OffsetAndMetadata> offsets,
			String consumerGroupId) throws ProducerFencedException;
	
	/**
	 * See {@link KafkaProducer#commitTransaction()}
	 */
	void commitTransaction() throws ProducerFencedException;
	
	/**
	 * See {@link KafkaProducer#abortTransaction()}
	 */
	void abortTransaction() throws ProducerFencedException;
	
	/**
	 * See {@link KafkaProducer#send(ProducerRecord)}
	 */
	Future<RecordMetadata> send(ProducerRecord<K, V> record);
	
	/**
	 * See {@link KafkaProducer#send(ProducerRecord, Callback)}
	 */
	Future<RecordMetadata> send(ProducerRecord<K, V> record, Callback callback);
	
	/**
	 * See {@link KafkaProducer#flush()}
	 */
	void flush();
	
	/**
	 * See {@link KafkaProducer#partitionsFor(String)}
	 */
	List<PartitionInfo> partitionsFor(String topic);
	
	/**
	 * See {@link KafkaProducer#metrics()}
	 */
	Map<MetricName, ? extends Metric> metrics();
	
	/**
	 * See {@link KafkaProducer#close()}
	 */
	void close();
	
	/**
	 * See {@link KafkaProducer#close(long, TimeUnit)}
	 */
	void close(long timeout, TimeUnit unit);
	
}
