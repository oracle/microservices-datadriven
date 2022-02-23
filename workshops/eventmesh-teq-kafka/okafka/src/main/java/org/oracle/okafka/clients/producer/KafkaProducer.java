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

package org.oracle.okafka.clients.producer;

import static org.oracle.okafka.common.serialization.ExtendedSerializer.Wrapper.ensureExtended;

import java.net.InetSocketAddress;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.Collections;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Properties;

import org.oracle.okafka.clients.ClientUtils;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.clients.KafkaClient;
import org.oracle.okafka.clients.Metadata;
import org.oracle.okafka.clients.NetworkClient;
import org.oracle.okafka.clients.admin.AdminClientConfig;
import org.oracle.okafka.clients.consumer.OffsetAndMetadata;
import org.oracle.okafka.clients.producer.internals.AQKafkaProducer;
import org.oracle.okafka.clients.producer.internals.ProducerInterceptors;
import org.oracle.okafka.clients.producer.internals.ProducerMetrics;
import org.oracle.okafka.clients.producer.internals.RecordAccumulator;
import org.oracle.okafka.clients.producer.internals.SenderThread;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.Metric;
import org.oracle.okafka.common.MetricName;
import org.oracle.okafka.common.PartitionInfo;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.config.ConfigException;
import org.oracle.okafka.common.config.SslConfigs;
import org.oracle.okafka.common.errors.ApiException;
import org.oracle.okafka.common.errors.FeatureNotSupportedException;
import org.oracle.okafka.common.errors.InterruptException;
import org.oracle.okafka.common.errors.InvalidLoginCredentialsException;
import org.oracle.okafka.common.errors.ProducerFencedException;
import org.oracle.okafka.common.errors.RecordTooLargeException;
import org.oracle.okafka.common.errors.SerializationException;
import org.oracle.okafka.common.errors.TimeoutException;
import org.oracle.okafka.common.header.Header;
import org.oracle.okafka.common.header.Headers;
import org.oracle.okafka.common.header.internals.RecordHeaders;
import org.oracle.okafka.common.internals.ClusterResourceListeners;
import org.oracle.okafka.common.metrics.JmxReporter;
import org.oracle.okafka.common.metrics.MetricConfig;
import org.oracle.okafka.common.metrics.Metrics;
import org.oracle.okafka.common.metrics.MetricsReporter;
import org.oracle.okafka.common.metrics.Sensor;
import org.oracle.okafka.common.record.AbstractRecords;
import org.oracle.okafka.common.record.CompressionType;
import org.oracle.okafka.common.record.RecordBatch;
import org.oracle.okafka.common.serialization.ExtendedSerializer;
import org.oracle.okafka.common.serialization.Serializer;
import org.oracle.okafka.common.utils.AppInfoParser;
import org.oracle.okafka.common.utils.KafkaThread;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.common.utils.TNSParser;
import org.slf4j.Logger;


/**
 * Note: Topic name has to be in uppercase wherever used.
 * A Java client that publishes records into the Transactional Event Queues.
 * <p>
 * The producer internally stores these records in batches in a buffer pool. And IO thread running in the background sends these batches synchronously one at a time.
 * <p>
 * The producer is <i>thread safe</i> i.e multiple threads can use same producer instance to publish records.
 * <p>
 * Here is a simple example of using the producer to send records with strings containing sequential numbers as the key/value
 * pairs.
 * <pre>
 * {@code
 * Properties props = new Properties();
 * props.put("oracle.instance.name", "instancename");
 * props.put("oracle.service.name", "serviceid.regress.rdbms.dev.us.oracle.com");	    
 * props.put("oracle.user.name", "username");
 * props.put("oracle.password", "pwd");
 * props.put("bootstrap.servers", "localhost:9092");
 * props.put("batch.size", 16384);
 * props.put("linger.ms", 1);
 * props.put("buffer.memory", 33554432);
 * props.put("retries", 0);
 * props.put("key.serializer", "org.oracle.okafka.common.serialization.StringSerializer");
 * props.put("value.serializer", "org.oracle.okafka.common.serialization.StringSerializer");
 *
 * Producer<String, String> producer = new KafkaProducer<>(props);
 * for (int i = 0; i < 100; i++)
 *     producer.send(new ProducerRecord<String, String>("my-topic", Integer.toString(i), Integer.toString(i)));
 * producer.close();
 * }</pre>
 * <p>
 * The producer consists of a pool of buffer space that holds records that haven't yet been transmitted to the server
 * as well as a background I/O thread that is responsible for turning these records into requests and transmitting them
 * to the cluster. Failure to close the producer after use will leak these resources.
 * <p>
 * The {@link #send(ProducerRecord) send()} method is asynchronous. When called it adds the record to a buffer of pending record sends
 * and immediately returns. This allows the producer to batch together individual records for efficiency.
 * <p>
 * The <code>acks</code> config controls the criteria under which requests are considered complete. The "all" setting
 * we have specified will result in blocking on the full commit of the record, the slowest but most durable setting.
 * OKafka supports only default setting "all" 
 * <p>
 * The <code>retries</code> config resends the request if request fails with retriable excpetion.
 * </p>
 * The producer maintains buffers of unsent records for each partition. These buffers are of a size specified by
 * the <code>batch.size</code> config. Making this larger can result in more batching, but requires more memory (since we will
 * generally have one of these buffers for each active partition).
 * <p>
 * By default a buffer is available to send immediately even if there is additional unused space in the buffer. However if you
 * want to reduce the number of requests you can set <code>linger.ms</code> to something greater than 0. This will
 * instruct the producer to wait up to that number of milliseconds before sending a request in hope that more records will
 * arrive to fill up the same batch. This is analogous to Nagle's algorithm in TCP. For example, in the code snippet above,
 * likely all 100 records would be sent in a single request since we set our linger time to 1 millisecond. However this setting
 * would add 1 millisecond of latency to our request waiting for more records to arrive if we didn't fill up the buffer. Note that
 * records that arrive close together in time will generally batch together even with <code>linger.ms=0</code> so under heavy load
 * batching will occur regardless of the linger configuration; however setting this to something larger than 0 can lead to fewer, more
 * efficient requests when not under maximal load at the cost of a small amount of latency.
 * <p>
 * The <code>buffer.memory</code> controls the total amount of memory available to the producer for buffering. If records
 * are sent faster than they can be transmitted to the server then this buffer space will be exhausted. When the buffer space is
 * exhausted additional send calls will block. The threshold for time to block is determined by <code>max.block.ms</code> after which it throws
 * a TimeoutException.
 * <p>
 * The <code>key.serializer</code> and <code>value.serializer</code> instruct how to turn the key and value objects the user provides with
 * their <code>ProducerRecord</code> into bytes. You can use the included {@link org.oracle.okafka.common.serialization.ByteArraySerializer} or
 * {@link org.oracle.okafka.common.serialization.StringSerializer} for simple string or byte types.
 * <p>
 *  The producer doesn't support idempotency and transactional behaviour yet.
 * <p>
 * */
public class KafkaProducer<K, V> implements Producer<K, V> {
         private final Logger log;
         private static final AtomicInteger PROD_CLIENT_ID_SEQUENCE = new AtomicInteger(1); 
         private final String clientId;
         private static final String JMX_PREFIX = "kafka.producer";
         public static final String NETWORK_THREAD_PREFIX = "kafka-producer-network-thread";
         private final ProducerConfig prodConfigs;
         final Metrics metrics;
         private final ExtendedSerializer<K> keySerializer;
         private final ExtendedSerializer<V> valueSerializer;
         
         private final RecordAccumulator recordAccumulator;
         /**
     	 * The network client to use.
     	 */
     	 private final KafkaClient client;
         private final SenderThread sender;
         private final KafkaThread ioThread;
         private final Metadata metadata;
         private final ProducerInterceptors<K, V> interceptors;
         private final CompressionType compressionType;
         private final Partitioner partitioner;
         private final long totalMemorySize;
         private final long maxBlockTimeMs;
         private final Time time;  
         private final int maxRequestSize;
         private final int requestTimeoutMs;
		/**
	     * A producer is instantiated by providing a set of key-value pairs as configuration. Valid configuration strings
	     * are documented <a href="http://kafka.apache.org/documentation.html#producerconfigs">here</a>. Values can be
	     * either strings or Objects of the appropriate type (for example a numeric configuration would accept either the
	     * string "42" or the integer 42).
	     * <p>
	     * Note: after creating a {@code KafkaProducer} you must always {@link #close()} it to avoid resource leaks.
	     * @param configs   The producer configs
	     *
	     */
	    public KafkaProducer(final Map<String, Object> configs) {
	       this(configs, null, null);
	    }

	    /**
	     * A producer is instantiated by providing a set of key-value pairs as configuration, a key and a value {@link Serializer}.
	     * Valid configuration strings are documented <a href="http://kafka.apache.org/documentation.html#producerconfigs">here</a>.
	     * Values can be either strings or Objects of the appropriate type (for example a numeric configuration would accept
	     * either the string "42" or the integer 42).
	     * <p>
	     * Note: after creating a {@code KafkaProducer} you must always {@link #close()} it to avoid resource leaks.
	     * @param configs   The producer configs
	     * @param keySerializer  The serializer for key that implements {@link Serializer}. The configure() method won't be
	     *                       called in the producer when the serializer is passed in directly.
	     * @param valueSerializer  The serializer for value that implements {@link Serializer}. The configure() method won't
	     *                         be called in the producer when the serializer is passed in directly.
	     */
	    public KafkaProducer(Map<String, Object> configs, Serializer<K> keySerializer, Serializer<V> valueSerializer) {
	    	this(new ProducerConfig(ProducerConfig.addSerializerToConfig(configs, keySerializer, valueSerializer)), keySerializer, valueSerializer, null, null);
	    }

	    /**
	     * A producer is instantiated by providing a set of key-value pairs as configuration. Valid configuration strings
	     * are documented <a href="http://kafka.apache.org/documentation.html#producerconfigs">here</a>.
	     * <p>
	     * Note: after creating a {@code KafkaProducer} you must always {@link #close()} it to avoid resource leaks.
	     * @param properties   The producer configs
	     */
	    public KafkaProducer(Properties properties) {
	    	this(properties, null, null);
	    }

	    /**
	     * A producer is instantiated by providing a set of key-value pairs as configuration, a key and a value {@link Serializer}.
	     * Valid configuration strings are documented <a href="http://kafka.apache.org/documentation.html#producerconfigs">here</a>.
	     * <p>
	     * Note: after creating a {@code KafkaProducer} you must always {@link #close()} it to avoid resource leaks.
	     * @param properties   The producer configs
	     * @param keySerializer  The serializer for key that implements {@link Serializer}. The configure() method won't be
	     *                       called in the producer when the serializer is passed in directly.
	     * @param valueSerializer  The serializer for value that implements {@link Serializer}. The configure() method won't
	     *                         be called in the producer when the serializer is passed in directly.
	     */
	    public KafkaProducer(Properties properties, Serializer<K> keySerializer, Serializer<V> valueSerializer) {
	        
	    	this(new ProducerConfig(ProducerConfig.addSerializerToConfig(properties, keySerializer, valueSerializer)), keySerializer, valueSerializer, null, null);
	    }
	    

	   @SuppressWarnings("unchecked")
	   // visible for testing
	   KafkaProducer(ProducerConfig prodConfigs, Serializer<K> keySerializer, Serializer<V> valueSerializer, Metadata metadata, KafkaClient kafkaClient) {
		   Map<String, Object> userProvidedConfigs = prodConfigs.originals();
		   this.time = Time.SYSTEM;
		try {
	       this.prodConfigs = prodConfigs;
		   String clientId= prodConfigs.getString(ProducerConfig.CLIENT_ID_CONFIG);
		   if (clientId.length() <= 0)
	           clientId = "producer-" + PROD_CLIENT_ID_SEQUENCE.getAndIncrement();
	       this.clientId = clientId;
	       String transactionalId = null; // userProvidedConfigs.containsKey(ProducerConfig.TRANSACTIONAL_ID_CONFIG) ?
                   //(String) userProvidedConfigs.get(ProducerConfig.TRANSACTIONAL_ID_CONFIG) : null;
	       LogContext logContext;
           if (transactionalId == null)
               logContext = new LogContext(String.format("[Producer clientId=%s] ", clientId));
           else
               logContext = new LogContext(String.format("[Producer clientId=%s, transactionalId=%s] ", clientId, transactionalId));
           log = logContext.logger(KafkaProducer.class);
           log.trace("Starting the Kafka producer");
           
           Map<String, String> metricTags = Collections.singletonMap("client-id", clientId);
           MetricConfig metricConfig = new MetricConfig().samples(prodConfigs.getInt(ProducerConfig.METRICS_NUM_SAMPLES_CONFIG))
                   .timeWindow(prodConfigs.getLong(ProducerConfig.METRICS_SAMPLE_WINDOW_MS_CONFIG), TimeUnit.MILLISECONDS)
                   .recordLevel(Sensor.RecordingLevel.forName(prodConfigs.getString(ProducerConfig.METRICS_RECORDING_LEVEL_CONFIG)))
                   .tags(metricTags);
           List<MetricsReporter> reporters = prodConfigs.getConfiguredInstances(ProducerConfig.METRIC_REPORTER_CLASSES_CONFIG,
                   MetricsReporter.class);
           reporters.add(new JmxReporter(JMX_PREFIX));
           this.metrics = new Metrics(metricConfig, reporters, time);
           ProducerMetrics metricsRegistry = new ProducerMetrics(this.metrics);

	       if (keySerializer == null) {
               this.keySerializer = ensureExtended(prodConfigs.getConfiguredInstance(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                                                                                        Serializer.class));
               this.keySerializer.configure(prodConfigs.originals(), true);
           } else {
               prodConfigs.ignore(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG);
               this.keySerializer = ensureExtended(keySerializer);
           }
           if (valueSerializer == null) {
               this.valueSerializer = ensureExtended(prodConfigs.getConfiguredInstance(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                                                                                          Serializer.class));
               this.valueSerializer.configure(prodConfigs.originals(), false);
           } else {
               prodConfigs.ignore(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG);
               this.valueSerializer = ensureExtended(valueSerializer);
           }  
           
           long retryBackoffMs = prodConfigs.getLong(ProducerConfig.RETRY_BACKOFF_MS_CONFIG);
           // load interceptors and make sure they get clientId
           userProvidedConfigs.put(ProducerConfig.CLIENT_ID_CONFIG, clientId);
           List<ProducerInterceptor<K, V>> interceptorList = (List) (new ProducerConfig(userProvidedConfigs, false)).getConfiguredInstances(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG,
                   ProducerInterceptor.class);
           this.interceptors = new ProducerInterceptors<>(interceptorList);
           ClusterResourceListeners clusterResourceListeners = configureClusterResourceListeners(keySerializer, valueSerializer, interceptorList, reporters);
           List<InetSocketAddress> addresses = null;
           String serviceName = null;
           String instanceName = null;
           System.setProperty("oracle.net.tns_admin", prodConfigs.getString(ProducerConfig.ORACLE_NET_TNS_ADMIN));
           
           if( prodConfigs.getString( CommonClientConfigs.SECURITY_PROTOCOL_CONFIG).trim().equalsIgnoreCase("PLAINTEXT"))
             addresses = ClientUtils.parseAndValidateAddresses(prodConfigs.getList(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG));
           else {
        	   if( prodConfigs.getString(SslConfigs.TNS_ALIAS) == null)
        		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
        	   TNSParser parser = new TNSParser(prodConfigs);
        	   parser.readFile();
        	   String connStr = parser.getConnectionString(prodConfigs.getString(SslConfigs.TNS_ALIAS).toUpperCase());
        	   if (connStr == null)
        		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
        	   String host = parser.getProperty(connStr, "HOST");
        	   String  portStr = parser.getProperty(connStr, "PORT");
        	   serviceName = parser.getProperty(connStr, "SERVICE_NAME");
        	   int port;
        	   if( host == null || portStr == null || serviceName == null)
        		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
        	   try {
        	   port = Integer.parseInt(portStr);
        	   } catch(NumberFormatException nfe) {
        		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
        	   }
        	   instanceName = parser.getProperty(connStr, "INSTANCE_NAME");
        	   addresses =  new ArrayList<>();
        	   addresses.add(new InetSocketAddress(host, port));  
           }
           if (metadata != null) {
               this.metadata = metadata;
           } else {
               this.metadata = new Metadata(retryBackoffMs, prodConfigs.getLong(ProducerConfig.METADATA_MAX_AGE_CONFIG),
                   true, true, clusterResourceListeners, prodConfigs);
               this.metadata.update(Cluster.bootstrap(addresses, prodConfigs, serviceName, instanceName), Collections.<String>emptySet(), time.milliseconds());
           }
           
           this.compressionType = CompressionType.forName(prodConfigs.getString(ProducerConfig.COMPRESSION_TYPE_CONFIG));
           this.partitioner = prodConfigs.getConfiguredInstance(ProducerConfig.PARTITIONER_CLASS_CONFIG, Partitioner.class);
           this.maxRequestSize = prodConfigs.getInt(ProducerConfig.MAX_REQUEST_SIZE_CONFIG);
           this.requestTimeoutMs = Integer.MAX_VALUE; //prodConfigs.getInt(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG);
           this.totalMemorySize = prodConfigs.getLong(ProducerConfig.BUFFER_MEMORY_CONFIG);
           this.maxBlockTimeMs = prodConfigs.getLong(ProducerConfig.MAX_BLOCK_MS_CONFIG);
           int retries = configureRetries(prodConfigs, false, log);
           int maxInflightRequests = 1; //configureInflightRequests(prodConfigs, false);
           short acks = configureAcks(prodConfigs, false, log);
          
           this.recordAccumulator = new RecordAccumulator(logContext,
                   prodConfigs.getInt(ProducerConfig.BATCH_SIZE_CONFIG),
                   this.totalMemorySize,
                   this.compressionType,
                   prodConfigs.getLong(ProducerConfig.LINGER_MS_CONFIG),
                   retryBackoffMs,
                   null,
                   time);

           client = kafkaClient != null ? kafkaClient : new NetworkClient(new AQKafkaProducer(logContext, prodConfigs, time), this.metadata, clientId,
        		    prodConfigs.getLong(AdminClientConfig.RECONNECT_BACKOFF_MS_CONFIG),
        		    prodConfigs.getLong(AdminClientConfig.RECONNECT_BACKOFF_MAX_MS_CONFIG),
        		    prodConfigs.getInt(AdminClientConfig.SEND_BUFFER_CONFIG),
        		    prodConfigs.getInt(AdminClientConfig.RECEIVE_BUFFER_CONFIG), (int) TimeUnit.HOURS.toMillis(1), time,
					logContext);

		   this.sender = new SenderThread(logContext,
				   this.clientId,
				   client,
                   this.metadata,
                   this.recordAccumulator,
                   false,
                   prodConfigs.getInt(ProducerConfig.MAX_REQUEST_SIZE_CONFIG),
                   acks,
                   retries,
                   null,
                   Time.SYSTEM,
                   this.requestTimeoutMs,
                   prodConfigs.getLong(ProducerConfig.RETRY_BACKOFF_MS_CONFIG));
		   String ioThreadName = NETWORK_THREAD_PREFIX + " | " + clientId;
           this.ioThread = new KafkaThread(ioThreadName, this.sender, false);
           this.ioThread.start();           
           AppInfoParser.registerAppInfo(JMX_PREFIX, this.clientId, null);
		}
		catch(Throwable t)
		{
			
			// call close methods if internal objects are already constructed this is to prevent resource leak. see KAFKA-2121
            close(0, TimeUnit.MILLISECONDS, true);
            // now propagate the exception
            throw new KafkaException("Failed to construct kafka producer", t);
		}
		
	   }
           
	    /**
	     * This api is not yet supported
	     */
		@Override
		public void initTransactions() {
			throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }

		 /**
	     * This api is not yet supported
	     */
	    @Override
	    public void beginTransaction() throws ProducerFencedException {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }
           
	    /**
	     * This api is not yet supported
	     */
	    @Override
	    public void sendOffsetsToTransaction(Map<TopicPartition, OffsetAndMetadata> offsets,
	                                  String consumerGroupId) throws ProducerFencedException {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    	
	    }
            
	    /**
	     * This api is not yet supported
	     */
	    @Override
	    public void commitTransaction() throws ProducerFencedException {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }
        
	    /**
	     * This api is not yet supported
	     */
	    @Override
	    public void abortTransaction() throws ProducerFencedException {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }
	    
	    
        /**
         * Asynchronously send a record to a topic. Equivalent to <code>send(record, null)</code>.
         * See {@link #send(ProducerRecord, Callback)} for details.
         */
	    @Override
	    public  Future<RecordMetadata> send(ProducerRecord<K, V> record) {
	    	
	    	return send(record, null);
	    }
	    
	    /**
	     * Asynchronously send a record to a topic and invoke the provided callback when the send has been acknowledged.
	     * <p>
	     * The send is asynchronous and this method will return immediately once the record has been stored in the buffer of
	     * records waiting to be sent. If buffer memory is full then send call blocks for a maximum of time <code>max.block.ms</code> .This allows sending many records in parallel without blocking to wait for the
	     * response after each one.
	     * <p>
	     * The result of the send is a {@link RecordMetadata} specifying the partition the record was sent to, the offset
	     * it was assigned and the timestamp of the record. If
	     * {@link org.oracle.okafka.common.record.TimestampType#CREATE_TIME CreateTime} is used by the topic, the timestamp
	     * will be the user provided timestamp or the record send time if the user did not specify a timestamp for the
	     * record. If {@link org.oracle.okafka.common.record.TimestampType#LOG_APPEND_TIME LogAppendTime} is used for the
	     * topic, the timestamp will be the TEQ local time when the message is appended. OKafka currently supports only 
	     * LogAppendTime.
	     * <p>
	     * Send call returns a {@link Future Future} for the
	     * {@link RecordMetadata} that will be assigned to this record. Invoking {@link Future#get()
	     * get()} on this future will block until the associated request completes and then return the metadata for the record
	     * or throw any exception that occurred while sending the record.
	     * <p>
	     * If you want to simulate a simple blocking call you can call the <code>get()</code> method immediately:
	     *
	     * <pre>
	     * {@code
	     * byte[] key = "key".getBytes();
	     * byte[] value = "value".getBytes();
	     * ProducerRecord<byte[],byte[]> record = new ProducerRecord<byte[],byte[]>("my-topic", key, value)
	     * producer.send(record).get();
	     * }</pre>
	     * <p>
	     * Fully non-blocking usage can make use of the {@link Callback} parameter to provide a callback that
	     * will be invoked when the request is complete.
	     *
	     * <pre>
	     * {@code
	     * ProducerRecord<byte[],byte[]> record = new ProducerRecord<byte[],byte[]>("the-topic", key, value);
	     * producer.send(myRecord,
	     *               new Callback() {
	     *                   public void onCompletion(RecordMetadata metadata, Exception e) {
	     *                       if(e != null) {
	     *                          e.printStackTrace();
	     *                       } else {
	     *                          System.out.println("The offset of the record we just sent is: " + metadata.offset());
	     *                       }
	     *                   }
	     *               });
	     * }
	     * </pre>
	     *
	     * Callbacks for records being sent to the same partition are guaranteed to execute in order. That is, in the
	     * following example <code>callback1</code> is guaranteed to execute before <code>callback2</code>:
	     *
	     * <pre>
	     * {@code
	     * producer.send(new ProducerRecord<byte[],byte[]>(topic, partition, key1, value1), callback1);
	     * producer.send(new ProducerRecord<byte[],byte[]>(topic, partition, key2, value2), callback2);
	     * }
	     * </pre>	    
	     * Note that callbacks will generally execute in the I/O thread of the producer and so should be reasonably fast or
	     * they will delay the sending of messages from other threads. If you want to execute blocking or computationally
	     * expensive callbacks it is recommended to use your own {@link java.util.concurrent.Executor} in the callback body
	     * to parallelize processing.
	     *
	     * @param record The record to send
	     * @param callback A user-supplied callback to execute when the record has been acknowledged by the server (null
	     *        indicates no callback)
	     *
	     * @throws InterruptException If the thread is interrupted while blocked
	     * @throws SerializationException If the key or value are not valid objects given the configured serializers
	     * @throws TimeoutException If the time taken for fetching metadata or allocating memory for the record has surpassed <code>max.block.ms</code>.
	     * @throws KafkaException If a Kafka related error occurs that does not belong to the public API exceptions.
	     */
	    @Override
	    public Future<RecordMetadata> send(ProducerRecord<K, V> record, Callback callback) {
	        // intercept the record, which can be potentially modified; this method does not throw exceptions
	        ProducerRecord<K, V> interceptedRecord = this.interceptors.onSend(record);
	        return doSend(interceptedRecord, callback);
	    }

	    
	    /**
	     * Implementation of asynchronously send a record to a topic.
	     */
	    private Future<RecordMetadata> doSend(ProducerRecord<K, V> record, Callback callback) {
	    	TopicPartition tp = null;
	    	try {
	    		throwIfProducerClosed();

				// TODO Debugging doSend records
				log.debug("Sending records start!");
				log.debug("record: key {}, message {} ", record.topic(), record.value());

	            // first make sure the metadata for the topic is available
	            ClusterAndWaitTime clusterAndWaitTime;
	            try {
	                clusterAndWaitTime = waitOnMetadata(record.topic(), record.partition(), maxBlockTimeMs);
	            } catch (KafkaException e) {
	                if (metadata.isClosed())
	                    throw new KafkaException("Producer closed while send in progress", e);
	                throw e;
	            }
	            long remainingWaitMs = Math.max(0, maxBlockTimeMs - clusterAndWaitTime.waitedOnMetadataMs);
	    		byte[] serializedKey;
		    	try {
		    		serializedKey = keySerializer.serialize(record.topic(),record.headers(), record.key());
		    	}
		    	catch(ClassCastException cce) {
		    		throw new SerializationException("Can't convert key of class " + record.key().getClass().getName() + " to class "
		    	              + prodConfigs.getClass(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG).getName() + " specified in key.serializer", cce);
		    	}
		    	
		    	byte[] serializedValue;
		    	try {
		    		serializedValue = valueSerializer.serialize(record.topic(), record.headers(), record.value());
		    	}
		    	catch(ClassCastException cce) {
		    		throw new SerializationException("Can't convert value of class " + record.value().getClass().getName() + " to class "
	                          + prodConfigs.getClass(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG).getName() + " specified in value.serializer", cce);	    	
		        }
		    	int partition = partition(record, serializedKey, serializedValue, metadata.fetch());
		    	
	            tp = new TopicPartition(record.topic(), partition);
				// TODO Debugging doSend records
				log.debug("Sending records :: Topic {} created!", tp.topic());

	            setReadOnly(record.headers());
	            Header[] headers = record.headers().toArray();

	            int serializedSize = AbstractRecords.estimateSizeInBytesUpperBound(RecordBatch.CURRENT_MAGIC_VALUE, compressionType,
	                   serializedKey, serializedValue, headers);
	            ensureValidRecordSize(serializedSize);
	            long timestamp = record.timestamp() == null ? time.milliseconds() : record.timestamp();

				// TODO Debugging doSend : return to trace
				log.debug("Sending record {} with callback {} to topic {} partition {}", record, callback, record.topic(), partition);

	            Callback interceptCallback = new InterceptorCallback<>(callback, this.interceptors, tp);

				RecordAccumulator.RecordAppendResult result = recordAccumulator.append(tp, timestamp, serializedKey,
	                    serializedValue, headers, interceptCallback ,remainingWaitMs);

				return result.future;
	    	} catch (ApiException e) {
	            log.debug("Exception occurred during message send:", e);
	            if (callback != null)
	                callback.onCompletion(null, e);
	            //this.errors.record();
	            this.interceptors.onSendError(record, tp, e);
	            return new FutureFailure(e);
	        } catch (InterruptedException e) {
	            //this.errors.record();
	            this.interceptors.onSendError(record, tp, e);
	            throw new InterruptException(e);
	        } catch (BufferExhaustedException e) {
	            //this.errors.record();
	            //this.metrics.sensor("buffer-exhausted-records").record();
	            this.interceptors.onSendError(record, tp, e);
	            throw e;
	        } catch (KafkaException e) {
	            //this.errors.record();
	            this.interceptors.onSendError(record, tp, e);
	            throw e;
	        } catch (Exception e) {
	            // we notify interceptor about all exceptions, since onSend is called before anything else in this method
	            this.interceptors.onSendError(record, tp, e);
	            throw e;
	        }
	    }

	    /**
	     * This api is not yet supported
	     */
	    @Override
	    public void flush() {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }

	    /**
	     * Get the partition metadata for the given topic. This can be used for custom partitioning.
	     * @throws InterruptException if the thread is interrupted while blocked
	     * @throws TimeoutException if metadata could not be refreshed within {@code max.block.ms}
	     * @throws KafkaException for all Kafka-related exceptions, including the case where this method is called after producer close
	     */
	    @Override
	    public  List<PartitionInfo> partitionsFor(String topic) {
	    	Objects.requireNonNull(topic, "topic cannot be null");
	        try {
	            return waitOnMetadata(topic, null, maxBlockTimeMs).cluster.partitionsForTopic(topic);
	        } catch (InterruptedException e) {
	            throw new InterruptException(e);
	        }
	    }

	    /**
	     * This api is not yet supported
	     */
	    @Override
	    public Map<MetricName, ? extends Metric> metrics() {
	    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
	    }

	  
	    /**
	     * Close this producer. This method blocks until all previously sent requests complete.
	     * This method is equivalent to <code>close(Long.MAX_VALUE, TimeUnit.MILLISECONDS)</code>.
	     * <p>
	     * <strong>If close() is called from {@link Callback}, a warning message will be logged and close(0, TimeUnit.MILLISECONDS)
	     * will be called instead. We do this because the sender thread would otherwise try to join itself and
	     * block forever.</strong>
	     * <p>
	     *
	     * @throws InterruptException If the thread is interrupted while blocked
	     */
	    @Override
	    public void close() {
	        close(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
	    }

	    /**
	     * This method waits up to <code>timeout</code> for the producer to complete the sending of all incomplete requests.
	     * <p>
	     * If the producer is unable to complete all requests before the timeout expires, this method will fail
	     * any unsent and unacknowledged records immediately.
	     * <p>
	     * If invoked from within a {@link Callback} this method will not block and will be equivalent to
	     * <code>close(0, TimeUnit.MILLISECONDS)</code>. This is done since no further sending will happen while
	     * blocking the I/O thread of the producer.
	     *
	     * @param timeout The maximum time to wait for producer to complete any pending requests. The value should be
	     *                non-negative. Specifying a timeout of zero means do not wait for pending send requests to complete.
	     * @param timeUnit The time unit for the <code>timeout</code>
	     * @throws InterruptException If the thread is interrupted while blocked
	     * @throws IllegalArgumentException If the <code>timeout</code> is negative.
	     */
	    @Override
	    public void close(long timeout, TimeUnit timeUnit) {
	        close(timeout, timeUnit, false);
	    }

	    private void close(long timeout, TimeUnit timeUnit, boolean swallowException) {
	        if (timeout < 0)
	            throw new IllegalArgumentException("The timeout cannot be negative.");

	        log.info("Closing the Kafka producer with timeoutMillis = {} ms.", timeUnit.toMillis(timeout));
	        // this will keep track of the first encountered exception
	        AtomicReference<Throwable> firstException = new AtomicReference<>();
	        boolean invokedFromCallback = Thread.currentThread() == this.ioThread;
	        if (timeout > 0) {
	            if (invokedFromCallback) {
	                log.warn("Overriding close timeout {} ms to 0 ms in order to prevent useless blocking due to self-join. " +
	                        "This means you have incorrectly invoked close with a non-zero timeout from the producer call-back.", timeout);
	            } else {
	                // Try to close gracefully.
	                if (this.sender != null)
	                    this.sender.initiateClose();
	                if (this.ioThread != null) {
	                    try {
	                        this.ioThread.join(timeUnit.toMillis(timeout));
	                    } catch (InterruptedException t) {
	                        firstException.compareAndSet(null, new InterruptException(t));
	                        log.error("Interrupted while joining ioThread", t);
	                    }
	                }
	            }
	        }

	        if (this.sender != null && this.ioThread != null && this.ioThread.isAlive()) {
	            log.info("Proceeding to force close the producer since pending requests could not be completed " +
	                    "within timeout {} ms.", timeout);
	            this.sender.forceClose();
	            // Only join the sender thread when not calling from callback.
	            if (!invokedFromCallback) {
	                try {
	                    this.ioThread.join();
	                } catch (InterruptedException e) {
	                    firstException.compareAndSet(null, new InterruptException(e));
	                }
	            }
	        }

	        ClientUtils.closeQuietly(interceptors, "producer interceptors", firstException);
	        ClientUtils.closeQuietly(metrics, "producer metrics", firstException);
	        ClientUtils.closeQuietly(keySerializer, "producer keySerializer", firstException);
	        ClientUtils.closeQuietly(valueSerializer, "producer valueSerializer", firstException);
	        ClientUtils.closeQuietly(partitioner, "producer partitioner", firstException);
	        AppInfoParser.unregisterAppInfo(JMX_PREFIX, clientId, null);
	        log.debug("Kafka producer has been closed");
	        Throwable exception = firstException.get();
	        if (exception != null && !swallowException) {
	            if (exception instanceof InterruptException) {
	                throw (InterruptException) exception;
	            }
	            throw new KafkaException("Failed to close kafka producer", exception);
	        }
	    }
	    private void throwIfProducerClosed() {
	        if (ioThread == null || !ioThread.isAlive()) {
				// TODO Debugging Send throwIfProducerClosed
				log.debug("Cannot perform operation after producer has been closed");
				throw new IllegalStateException("Cannot perform operation after producer has been closed");
			}
	    }
	    
	    /**
	     * Wait for cluster metadata including partitions for the given topic to be available.
	     * @param topic The topic we want metadata for
	     * @param partition A specific partition expected to exist in metadata, or null if there's no preference
	     * @param maxWaitMs The maximum time in ms for waiting on the metadata
	     * @return The cluster containing topic metadata and the amount of time we waited in ms
	     * @throws KafkaException for all Kafka-related exceptions, including the case where this method is called after producer close
	     */
	    private ClusterAndWaitTime waitOnMetadata(String topic, Integer partition, long maxWaitMs) throws InterruptedException { 
	        // add topic to metadata topic list if it is not there already and reset expiry
	        metadata.add(topic);Cluster cluster = null;try {
	        cluster = metadata.fetch();} catch(Exception e) {
	        	throw new InterruptedException();
	        }
	        Integer partitionsCount = cluster.partitionCountForTopic(topic);

	        // Return cached metadata if we have it, and if the record's partition is either undefined
	        // or within the known partition range
	        if (partitionsCount != null && (partition == null || partition < partitionsCount))
	            return new ClusterAndWaitTime(cluster, 0);

	        long begin = time.milliseconds();
	        long remainingWaitMs = maxWaitMs;
	        long elapsed;
	        // Issue metadata requests until we have metadata for the topic or maxWaitTimeMs is exceeded.
	        // In case we already have cached metadata for the topic, but the requested partition is greater
	        // than expected, issue an update request only once. This is necessary in case the metadata
	        // is stale and the number of partitions for this topic has increased in the meantime.
	        do {
	            log.trace("Requesting metadata update for topic {}.", topic);
	            metadata.add(topic);
	            int version = metadata.requestUpdate();
	            try {
	                metadata.awaitUpdate(version, remainingWaitMs);
	            } catch (TimeoutException ex) {
	                // Rethrow with original maxWaitMs to prevent logging exception with remainingWaitMs
	                throw new TimeoutException("Failed to update metadata after " + maxWaitMs + " ms.");
	            }
	            cluster = metadata.fetch();
	            elapsed = time.milliseconds() - begin;
	            if (elapsed >= maxWaitMs)
	                throw new TimeoutException("Failed to update metadata after " + maxWaitMs + " ms.");
	            remainingWaitMs = maxWaitMs - elapsed;
	            partitionsCount = cluster.partitionCountForTopic(topic);
	            
	        } while (partitionsCount == null);

	        if (partition != null && partition >= partitionsCount) {
	            throw new KafkaException(
	                    String.format("Invalid partition given with record: %d is not in the range [0...%d).", partition, partitionsCount));
	        }

	        return new ClusterAndWaitTime(cluster, elapsed);
	    }


	    /**
	     * computes partition for given record.
	     * if the record has partition returns the value otherwise
	     * calls configured partitioner class to compute the partition.
	     */
	    private int partition(ProducerRecord<K, V> record, byte[] serializedKey, byte[] serializedValue, Cluster cluster) {
	        Integer partition = record.partition();
	        return partition != null ?
	                partition :
	                partitioner.partition(
	                        record.topic(), record.key(), serializedKey, record.value(), serializedValue, cluster);
	    }
	    
	    private void setReadOnly(Headers headers) {
	        if (headers instanceof RecordHeaders) {
	            ((RecordHeaders) headers).setReadOnly();
	        }
	    }
	    
	    /**
	     * Validate that the record size isn't too large
	     */
	    private void ensureValidRecordSize(int size) {
	        if (size > this.totalMemorySize)
	            throw new RecordTooLargeException("The message is " + size +
	                    " bytes when serialized which is larger than the total memory buffer you have configured with the " +
	                    ProducerConfig.BUFFER_MEMORY_CONFIG +
	                    " configuration.");
	    }
	    
	    private static int parseAcks(String acksString) {
	        try {
	            return acksString.trim().equalsIgnoreCase("all") ? -1 : Integer.parseInt(acksString.trim());
	        } catch (NumberFormatException e) {
	            throw new ConfigException("Invalid configuration value for 'acks': " + acksString);
	        }
	    }
	    
	    private ClusterResourceListeners configureClusterResourceListeners(Serializer<K> keySerializer, Serializer<V> valueSerializer, List<?>... candidateLists) {
	        ClusterResourceListeners clusterResourceListeners = new ClusterResourceListeners();
	        for (List<?> candidateList: candidateLists)
	            clusterResourceListeners.maybeAddAll(candidateList);

	        clusterResourceListeners.maybeAdd(keySerializer);
	        clusterResourceListeners.maybeAdd(valueSerializer);
	        return clusterResourceListeners;
	    }
	    
	    private static int configureRetries(ProducerConfig config, boolean idempotenceEnabled, Logger log) {
	        boolean userConfiguredRetries = false;
	        if (config.originals().containsKey(ProducerConfig.RETRIES_CONFIG)) {
	            userConfiguredRetries = true;
	        }
	        if (idempotenceEnabled && !userConfiguredRetries) {
	            // We recommend setting infinite retries when the idempotent producer is enabled, so it makes sense to make
	            // this the default.
	            log.info("Overriding the default retries config to the recommended value of {} since the idempotent " +
	                    "producer is enabled.", Integer.MAX_VALUE);
	            return Integer.MAX_VALUE;
	        }
	        if (idempotenceEnabled && config.getInt(ProducerConfig.RETRIES_CONFIG) == 0) {
	            throw new ConfigException("Must set " + ProducerConfig.RETRIES_CONFIG + " to non-zero when using the idempotent producer.");
	        }
	        return config.getInt(ProducerConfig.RETRIES_CONFIG);
	    }

	    private static int configureInflightRequests(ProducerConfig config, boolean idempotenceEnabled) {
	        if (idempotenceEnabled && 5 < config.getInt(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION)) {
	            throw new ConfigException("Must set " + ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION + " to at most 5" +
	                    " to use the idempotent producer.");
	        }
	        return config.getInt(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION);
	    }

	    
	    private static short configureAcks(ProducerConfig config, boolean idempotenceEnabled, Logger log) {
	        boolean userConfiguredAcks = false;
	        short acks = (short) parseAcks(config.getString(ProducerConfig.ACKS_CONFIG));
	        if (config.originals().containsKey(ProducerConfig.ACKS_CONFIG)) {
	            userConfiguredAcks = true;
	        }

	        if (idempotenceEnabled && !userConfiguredAcks) {
	            log.info("Overriding the default {} to all since idempotence is enabled.", ProducerConfig.ACKS_CONFIG);
	            return -1;
	        }

	        if (idempotenceEnabled && acks != -1) {
	            throw new ConfigException("Must set " + ProducerConfig.ACKS_CONFIG + " to all in order to use the idempotent " +
	                    "producer. Otherwise we cannot guarantee idempotence.");
	        }
	        return acks;
	    }

	    
	    private static class ClusterAndWaitTime {
	        final Cluster cluster;
	        final long waitedOnMetadataMs;
	        ClusterAndWaitTime(Cluster cluster, long waitedOnMetadataMs) {
	            this.cluster = cluster;
	            this.waitedOnMetadataMs = waitedOnMetadataMs;
	        }
	    }
	    
	    private static class FutureFailure implements Future<RecordMetadata> {

	        private final ExecutionException exception;

	        public FutureFailure(Exception exception) {
	            this.exception = new ExecutionException(exception);
	        }

	        @Override
	        public boolean cancel(boolean interrupt) {
	            return false;
	        }

	        @Override
	        public RecordMetadata get() throws ExecutionException {
	            throw this.exception;
	        }

	        @Override
	        public RecordMetadata get(long timeout, TimeUnit unit) throws ExecutionException {
	            throw this.exception;
	        }

	        @Override
	        public boolean isCancelled() {
	            return false;
	        }

	        @Override
	        public boolean isDone() {
	            return true;
	        }

	    }

	    /**
	     * A callback called when producer request is complete. It in turn calls user-supplied callback (if given) and
	     * notifies producer interceptors about the request completion.
	     */
	    private static class InterceptorCallback<K, V> implements Callback {
	        private final Callback userCallback;
	        private final ProducerInterceptors<K, V> interceptors;
	        private final TopicPartition tp;

	        private InterceptorCallback(Callback userCallback, ProducerInterceptors<K, V> interceptors, TopicPartition tp) {
	            this.userCallback = userCallback;
	            this.interceptors = interceptors;
	            this.tp = tp;
	        }

	        public void onCompletion(RecordMetadata metadata, Exception exception) {
	            metadata = metadata != null ? metadata : new RecordMetadata(tp, -1, -1, RecordBatch.NO_TIMESTAMP, Long.valueOf(-1L), -1, -1);
	            this.interceptors.onAcknowledgement(metadata, exception);
	            if (this.userCallback != null)
	                this.userCallback.onCompletion(metadata, exception);
	        }
	    }

}
