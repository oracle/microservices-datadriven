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

package org.oracle.okafka.clients.consumer;

import java.net.InetSocketAddress;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.ConcurrentModificationException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Pattern;

import javax.jms.JMSException;

import oracle.jms.AQjmsBytesMessage;

import org.oracle.okafka.clients.ClientUtils;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.clients.Metadata;
import org.oracle.okafka.clients.NetworkClient;
import org.oracle.okafka.clients.consumer.internals.ConsumerInterceptors;
import org.oracle.okafka.clients.consumer.internals.ConsumerMetrics;
import org.oracle.okafka.clients.consumer.internals.ConsumerNetworkClient;
import org.oracle.okafka.clients.consumer.internals.NoOpConsumerRebalanceListener;
import org.oracle.okafka.clients.consumer.internals.SubscriptionState;
import org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.Metric;
import org.oracle.okafka.common.MetricName;
import org.oracle.okafka.common.PartitionInfo;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.config.SslConfigs;
import org.oracle.okafka.common.errors.AuthenticationException;
import org.oracle.okafka.common.errors.FeatureNotSupportedException;
import org.oracle.okafka.common.errors.InvalidLoginCredentialsException;
import org.oracle.okafka.common.header.internals.RecordHeaders;
import org.oracle.okafka.common.internals.ClusterResourceListeners;
import org.oracle.okafka.common.metrics.JmxReporter;
import org.oracle.okafka.common.metrics.MetricConfig;
import org.oracle.okafka.common.metrics.Metrics;
import org.oracle.okafka.common.metrics.MetricsReporter;
import org.oracle.okafka.common.metrics.Sensor;
import org.oracle.okafka.common.record.TimestampType;
import org.oracle.okafka.common.requests.IsolationLevel;
import org.oracle.okafka.common.serialization.Deserializer;
import org.oracle.okafka.common.utils.AppInfoParser;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.MessageIdConverter;
import org.oracle.okafka.common.utils.TNSParser;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.common.utils.Utils;
import org.slf4j.Logger;


/**
 * Note: Topic name has to be in uppercase wherever used.
 * A Java client that consumes records from a Transactional event queues.
 * The consumer maintains a single jms session to any one of the available instance of oracle database to fetch data.
 * Failure to close the consumer after use will leak this connection.
 *
 * <h3><a name="consumergroups">Consumer Groups and Topic Subscriptions</a></h3>
 *
 * TEQ uses the concept of <i>consumer groups</i> to allow a pool of processes to divide the work of consuming and
 * processing records. These processes can either be running on the same machine or they can be
 * distributed over many machines to provide scalability and fault tolerance for processing. All consumer instances
 * sharing the same {@code group.id} will be part of the same consumer group.
 * <p>
 * In consumer group there can be multiple consumer instances. Each instance internally holds single connection and session to TEQ.
 * In 20c release or version 0.8 of OKafka.jar file, each consumer instance/session is assigned a single partition (or a single stream) of 
 * of subscribed topic. Client application has to start as many consumer instances as number of partitions of the topic.
 * If consumer instance goes down , messages from assigned partition are not dequeued untill new/same consumer instance comes up. 
 * However other instances continue consuming fron their assigned partition whether consumer instance goes up or down i.e. there is no consumer rebalancing in any situation. 
 * If oracle db instance goes down, consumer instance tries connecting to same oracle db instance and consumes from newly assigned partition.
 * <p>
 * A Consumer can subscribe to single topic using {@link #subscribe(Collection) subscribe}. Consumer throws an exception if topic subscription collection size is greater than one.
 * Also consumers can't subscribe using {@link #subscribe(Pattern) subscribe(Pattern)}, {@link #subscribe(Pattern, ConsumerRebalanceListener) subscribe(Pattern, ConsumerRebalanceListener)},
 * {@link #subscribe(Collection, ConsumerRebalanceListener) subscribe(Collection, ConsumerRebalanceListener)}.
 * 
 * <h3>Offsets and Consumer Position</h3>
 * TEQ maintains a string message id for each record in a partition .This id is equivalent to kafka offset. This offset or
 * msg id acts as a unique identifier of a record within that partition, and also denotes the position of the consumer 
 * in the partition. The position of consumer depends on {@link #commitSync() committed position}. This is the last offset that has been stored securely. Should the
 * process starts or fail and restart , this is the offset that the consumer will recover to. The consumer can either automatically commit
 * offsets periodically; or it can choose to control this committed position manually by calling one of the commit APIs
 * (e.g. {@link #commitSync() commitSync} and {@link #commitAsync(OffsetCommitCallback) commitAsync}).
 * Below examples show how to use periodic or manual offset commit.
 * 
 * <h4>Automatic Offset Committing</h4>
 * This example demonstrates a simple usage of oKafka's consumer api that relies on automatic offset committing.
 * <p>
 * <pre>
 * {@code
 *     Properties props = new Properties();
 *     props.put("oracle.service.name", "serviceid.regress.rdbms.dev.us.oracle.com");	    	     
 *     props.put("oracle.instance.name", "instancename");
 * 	   props.put("oracle.user.name", "username");
 * 	   props.put("oracle.password", "pwd");
 *	   props.put("bootstrap.servers", "IP:PORT");
 *     props.put("group.id", "groupid");
 *     props.put("enable.auto.commit", "true");
 *     props.put("auto.commit.interval.ms", "10000");
 *     props.put("key.deserializer",  "org.oracle.okafka.common.serialization.StringDeserializer");	      
 *     props.put("value.deserializer",    "org.oracle.okafka.common.serialization.StringDeserializer");  	    p
 *     rops.put("max.poll.records", 100);
 *     KafkaConsumer<String, String> consumer = null;
 *	   consumer = new KafkaConsumer<String, String>(props);
 *     consumer.subscribe(Arrays.asList(topic));
 *     ConsumerRecords<String, String> records = null; 
 *     try {
 *		   records = consumer.poll(Duration.ofMillis(1000));
 *	 	   for (ConsumerRecord<String, String> record : records) {		 	  	   
 *                   System.out.println("topic = , partition=  ,key= , value = \n"+ 		 	  	             
 *                                 record.topic()+ "  "+record.partition()+ "  "+record.key()+"  "+ record.value());                  
 *                  System.out.println(".......");
 * 	 	    }
 *	 	   consumer.commitSync();		 	  	    	 
 *	     }catch(Exception ex) {
 *	    	 ex.printStackTrace(); 
 *       } finally {
 *	    	 consumer.close();
 *	     } 
 *}
 * </pre>
 *
 * The connection to the cluster is bootstrapped by specifying a one broker to contact using the
 * configuration {@code bootstrap.servers}. 
 * <p>
 * Setting {@code enable.auto.commit} means that offsets are committed automatically with a frequency controlled by
 * the config {@code auto.commit.interval.ms}.
 * <p>
 * In this example the consumer is subscribing to the topic <i>foo</i>  as part of a group of consumers
 * called <i>groupid</i> as configured with {@code group.id}.
 * <p>
 * The deserializer settings specify how to turn bytes into objects. For example, by specifying string deserializers, we
 * are saying that our record's key and value will just be simple strings.
 * <p>
 * <h4>Manual Offset Control</h4>
 * <p>
 * Instead of relying on the consumer to periodically commit consumed offsets, users can also control when records
 * should be considered as consumed and hence commit their offsets. This is useful when the consumption of the messages
 * is coupled with some processing logic and hence a message should not be considered as consumed until it is completed processing.
 * <p>
 * <pre>
 *     Properties props = new Properties();
 *     props.put("oracle.service.name", "serviceid.regress.rdbms.dev.us.oracle.com");	    	     
 *     props.put("oracle.instance.name", "instancename");
 *     props.put("oracle.user.name", "username");
 *     props.put("oracle.password", "pwd");
 *     props.put("bootstrap.servers", "IP:PORT");
 *     props.put("group.id", "groupid");
 *     props.put("enable.auto.commit", "true");
 *     props.put("auto.commit.interval.ms", "10000");
 *     props.put("key.deserializer",  "org.oracle.okafka.common.serialization.StringDeserializer");	      
 *     props.put("value.deserializer",    "org.oracle.okafka.common.serialization.StringDeserializer");  	    
 *     props.put("max.poll.records", 100);
 *     KafkaConsumer<String, String> consumer = null;
 *     consumer = new KafkaConsumer<String, String>(props);
 *     consumer.subscribe(Arrays.asList(topic));
 *     ConsumerRecords<String, String> records = null; 
 *     try {
 *         final int minBatchSize = 200;
 *         List<ConsumerRecord<String, String>> buffer = new ArrayList<>();
 *         while (true) {
 *            ConsumerRecords<String, String> records = consumer.poll(100);
 *            for (ConsumerRecord<String, String> record : records) {
 *                 buffer.add(record);
 *             }
 *            if (buffer.size() <= minBatchSize) {
 *             insertIntoDb(buffer);
 *             consumer.commitSync();
 *             buffer.clear();
 *            }
 *         }		 	  	    	 
 *	     }catch(Exception ex) {
 *	    	 ex.printStackTrace(); 
 *       } finally {
 *	    	 consumer.close();
 *	     } 
 *
 * </pre>
 *
 * In this example we will consume a batch of records and batch them up in memory. When we have enough records
 * batched, we will insert them into a database. If our process fails before commitSync() then all consumed messages
 * after previous commit are rolled back and considered not consumed. If process restarted it starts consuming from 
 * next of previous committed offset(msgid).
 * <p>
 *
 * <h3><a name="multithreaded">Multi-threaded Processing</a></h3>
 *
 * <p>
 * The okafka consumer is NOT thread-safe. All network I/O happens in the thread of the application
 * making the call. It is the responsibility of the user to ensure that multi-threaded access
 * is properly synchronized. Un-synchronized access will result in {@link ConcurrentModificationException}.
 * <p>
 */

public class KafkaConsumer<K, V> implements Consumer<K, V> {

    private static final long NO_CURRENT_THREAD = -1L;
    private static final AtomicInteger CONSUMER_CLIENT_ID_SEQUENCE = new AtomicInteger(1);
    private static final String JMX_PREFIX = "kafka.consumer";
    static final long DEFAULT_CLOSE_TIMEOUT_MS = 30 * 1000;

    final Metrics metrics;

    private final Logger log;
    private final String clientId;
    private final Deserializer<K> keyDeserializer;
    private final Deserializer<V> valueDeserializer;
    private final ConsumerInterceptors<K, V> interceptors;

    private final Time time;
    private final SubscriptionState subscriptions;
    private final Metadata metadata;
    private final ConsumerNetworkClient client;
    private final long retryBackoffMs;
    private final int requestTimeoutMs;
    private final int defaultApiTimeoutMs;
    private volatile boolean closed = false;
    //private List<PartitionAssignor> assignors;

    // currentThread holds the threadId of the current thread accessing KafkaConsumer
    // and is used to prevent multi-threaded access
    private final AtomicLong currentThread = new AtomicLong(NO_CURRENT_THREAD);
    // refcount is used to allow reentrant access by the thread who has acquired currentThread
    private final AtomicInteger refcount = new AtomicInteger(0);

    /**
     * A consumer is instantiated by providing a set of key-value pairs as configuration. Valid configuration strings
     * are documented <a href="http://kafka.apache.org/documentation.html#consumerconfigs" >here</a>. Values can be
     * either strings or objects of the appropriate type (for example a numeric configuration would accept either the
     * string "42" or the integer 42).
     * <p>
     * Valid configuration strings are documented at {@link ConsumerConfig}.
     * <p>
     * Note: after creating a {@code KafkaConsumer} you must always {@link #close()} it to avoid resource leaks.
     *
     * @param configs The consumer configs
     */
    public KafkaConsumer(Map<String, Object> configs) {
        this(configs, null, null);
    }

    /**
     * A consumer is instantiated by providing a set of key-value pairs as configuration, and a key and a value {@link Deserializer}.
     * <p>
     * Valid configuration strings are documented at {@link ConsumerConfig}.
     * <p>
     * Note: after creating a {@code KafkaConsumer} you must always {@link #close()} it to avoid resource leaks.
     *
     * @param configs The consumer configs
     * @param keyDeserializer The deserializer for key that implements {@link Deserializer}. The configure() method
     *            won't be called in the consumer when the deserializer is passed in directly.
     * @param valueDeserializer The deserializer for value that implements {@link Deserializer}. The configure() method
     *            won't be called in the consumer when the deserializer is passed in directly.
     */
    public KafkaConsumer(Map<String, Object> configs,
                         Deserializer<K> keyDeserializer,
                         Deserializer<V> valueDeserializer) {
        this(new ConsumerConfig(ConsumerConfig.addDeserializerToConfig(configs, keyDeserializer, valueDeserializer)),
            keyDeserializer,
            valueDeserializer);
    }

    /**
     * A consumer is instantiated by providing a {@link Properties} object as configuration.
     * <p>
     * Valid configuration strings are documented at {@link ConsumerConfig}.
     * <p>
     * Note: after creating a {@code KafkaConsumer} you must always {@link #close()} it to avoid resource leaks.
     *
     * @param properties The consumer configuration properties
     */
    public KafkaConsumer(Properties properties) {
        this(properties, null, null);
    }

    /**
     * A consumer is instantiated by providing a {@link Properties} object as configuration, and a
     * key and a value {@link Deserializer}.
     * <p>
     * Valid configuration strings are documented at {@link ConsumerConfig}.
     * <p>
     * Note: after creating a {@code KafkaConsumer} you must always {@link #close()} it to avoid resource leaks.
     *
     * @param properties The consumer configuration properties
     * @param keyDeserializer The deserializer for key that implements {@link Deserializer}. The configure() method
     *            won't be called in the consumer when the deserializer is passed in directly.
     * @param valueDeserializer The deserializer for value that implements {@link Deserializer}. The configure() method
     *            won't be called in the consumer when the deserializer is passed in directly.
     */
    public KafkaConsumer(Properties properties,
                         Deserializer<K> keyDeserializer,
                         Deserializer<V> valueDeserializer) {
        this(new ConsumerConfig(ConsumerConfig.addDeserializerToConfig(properties, keyDeserializer, valueDeserializer)),
             keyDeserializer, valueDeserializer);
    }

    @SuppressWarnings("unchecked")
    private KafkaConsumer(ConsumerConfig config,
                          Deserializer<K> keyDeserializer,
                          Deserializer<V> valueDeserializer) {
        try {
            String clientId = config.getString(ConsumerConfig.CLIENT_ID_CONFIG);
            if (clientId.isEmpty())
                clientId = "consumer-" + CONSUMER_CLIENT_ID_SEQUENCE.getAndIncrement();
            this.clientId = clientId;
            String groupId = config.getString(ConsumerConfig.GROUP_ID_CONFIG);

            LogContext logContext = new LogContext("[Consumer clientId=" + clientId + ", groupId=" + groupId + "] ");
            this.log = logContext.logger(getClass());

            log.debug("Initializing the Kafka consumer");
            this.requestTimeoutMs = config.getInt(ConsumerConfig.REQUEST_TIMEOUT_MS_CONFIG);
            this.defaultApiTimeoutMs = config.getInt(ConsumerConfig.DEFAULT_API_TIMEOUT_MS_CONFIG);
            this.time = Time.SYSTEM;

            Map<String, String> metricsTags = Collections.singletonMap("client-id", clientId);
            MetricConfig metricConfig = new MetricConfig().samples(config.getInt(ConsumerConfig.METRICS_NUM_SAMPLES_CONFIG))
                    .timeWindow(config.getLong(ConsumerConfig.METRICS_SAMPLE_WINDOW_MS_CONFIG), TimeUnit.MILLISECONDS)
                    .recordLevel(Sensor.RecordingLevel.forName(config.getString(ConsumerConfig.METRICS_RECORDING_LEVEL_CONFIG)))
                    .tags(metricsTags);
            List<MetricsReporter> reporters = config.getConfiguredInstances(ConsumerConfig.METRIC_REPORTER_CLASSES_CONFIG,
                    MetricsReporter.class);
            reporters.add(new JmxReporter(JMX_PREFIX));
            this.metrics = new Metrics(metricConfig, reporters, time);
            this.retryBackoffMs = config.getLong(ConsumerConfig.RETRY_BACKOFF_MS_CONFIG);

            // load interceptors and make sure they get clientId
            Map<String, Object> userProvidedConfigs = config.originals();
            userProvidedConfigs.put(ConsumerConfig.CLIENT_ID_CONFIG, clientId);
            List<ConsumerInterceptor<K, V>> interceptorList = (List) (new ConsumerConfig(userProvidedConfigs, false)).getConfiguredInstances(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG,
                    ConsumerInterceptor.class);
            this.interceptors = new ConsumerInterceptors<>(interceptorList);

            if (keyDeserializer == null) {
                this.keyDeserializer = config.getConfiguredInstance(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
                        Deserializer.class);
                this.keyDeserializer.configure(config.originals(), true);
            } else {
                config.ignore(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG);
                this.keyDeserializer = keyDeserializer;
            }
            if (valueDeserializer == null) {
                this.valueDeserializer = config.getConfiguredInstance(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
                        Deserializer.class);
                this.valueDeserializer.configure(config.originals(), false);
            } else {
                config.ignore(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG);
                this.valueDeserializer = valueDeserializer;
            }
            ClusterResourceListeners clusterResourceListeners = configureClusterResourceListeners(keyDeserializer, valueDeserializer, reporters, interceptorList);
            this.metadata = new Metadata(Long.MAX_VALUE, config.getLong(ConsumerConfig.METADATA_MAX_AGE_CONFIG),
                    true, false, clusterResourceListeners, config);
        
            List<InetSocketAddress> addresses = null;
            String serviceName = null;
            String instanceName = null;
            System.setProperty("oracle.net.tns_admin", config.getString(ConsumerConfig.ORACLE_NET_TNS_ADMIN));
            if( config.getString( CommonClientConfigs.SECURITY_PROTOCOL_CONFIG).equalsIgnoreCase("PLAINTEXT"))
              addresses = ClientUtils.parseAndValidateAddresses(config.getList(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG));
            else {
         	   if( config.getString(SslConfigs.TNS_ALIAS) == null)
         		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
         	   TNSParser parser = new TNSParser(config);
         	   parser.readFile();
         	   String connStr = parser.getConnectionString(config.getString(SslConfigs.TNS_ALIAS).toUpperCase());
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
            this.metadata.update(Cluster.bootstrap(addresses, config, serviceName, instanceName), Collections.<String>emptySet(), time.milliseconds());
            String metricGrpPrefix = "consumer";
            ConsumerMetrics metricsRegistry = new ConsumerMetrics(metricsTags.keySet(), "consumer");

            IsolationLevel isolationLevel = IsolationLevel.valueOf(
                    config.getString(ConsumerConfig.ISOLATION_LEVEL_CONFIG).toUpperCase(Locale.ROOT));
            OffsetResetStrategy offsetResetStrategy = OffsetResetStrategy.valueOf(config.getString(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG).toUpperCase(Locale.ROOT));
            this.subscriptions = new SubscriptionState(offsetResetStrategy);
            int maxPollIntervalMs = config.getInt(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG);
            int sessionTimeoutMs = config.getInt(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG);

            NetworkClient networkClient = new NetworkClient(new AQKafkaConsumer(logContext, config, time), this.metadata, clientId,
            		config.getLong(ConsumerConfig.RECONNECT_BACKOFF_MS_CONFIG),
            		config.getLong(ConsumerConfig.RECONNECT_BACKOFF_MAX_MS_CONFIG),
            		config.getInt(ConsumerConfig.SEND_BUFFER_CONFIG),
            		config.getInt(ConsumerConfig.RECEIVE_BUFFER_CONFIG), (int) TimeUnit.HOURS.toMillis(1), time,
					logContext);

            this.client = new ConsumerNetworkClient(
            		logContext,
            		networkClient,
                    metadata,
                    subscriptions,
                    config.getBoolean(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG),
                    config.getInt(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG),
                    time,
                    retryBackoffMs,
                    maxPollIntervalMs,
                    this.requestTimeoutMs,
                    sessionTimeoutMs,
                    defaultApiTimeoutMs);

            config.logUnused();
            AppInfoParser.registerAppInfo(JMX_PREFIX, clientId, metrics);

            log.debug("Kafka consumer initialized");
        } catch (Throwable t) {
            // call close methods if internal objects are already constructed
            // this is to prevent resource leak.
            close(0, true);
            // now propagate the exception

            throw new KafkaException("Failed to construct kafka consumer", t);
        }
    }

    /**
     * This method is not yet supported.
     */
    public Set<TopicPartition> assignment() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    public Set<String> subscription() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * Subscribe to the given list of topics to get dynamically assigned partitions. However OKafka 0.8 supports 
     * only subscription to single topic and only one partition is assigned dynamically to consumer. Consumer fetches
     * messages from this partition for its lifetime. If consumer goes down then messages from this partition remains 
     * unconsumed. Client has to start a new consumer to consume from this partition.
     * 
     * <b>
     * Topic subscriptions are not incremental. This list will replace the current
     * assignment (if there is one).
     * </b> .
     *
     * If the given list of topics is empty, it is treated the same as {@link #unsubscribe()}.
     * This call has effect only when poll is invoked.
     * <p>
     * okafka 0.8 doesn't support consumer group rebalance listener i.e. <b>ConsumerRebalanceListener</b>.
     *
     * @param topics The list of topics to subscribe to
     * @param listener null if not null is ignored
     * @throws IllegalArgumentException If topics is null or contains null or empty elements or size of topics is greater than one.
     */
    @Override
    public void subscribe(Collection<String> topics, ConsumerRebalanceListener listener) {
    	
     acquireAndEnsureOpen();
        try {
            if (topics == null) {
                throw new IllegalArgumentException("Topic collection to subscribe to cannot be null");
            } else if (topics.isEmpty()) {
                // treat subscribing to empty topic list as the same as unsubscribing
                this.unsubscribe();
            } else {
            	if(topics.size() > 1) 
            		throw new IllegalArgumentException("Only one topic can be subscribed");
                for (String topic : topics) {
                    if (topic == null || topic.trim().isEmpty())
                        throw new IllegalArgumentException("Topic collection to subscribe to cannot contain null or empty topic");
                }
                log.debug("Subscribed to topic(s): {}", Utils.join(topics, ", "));
                this.subscriptions.subscribe(new HashSet<>(topics), listener);
                //metadata.setTopics(subscriptions.groupSubscription());
            }
        } finally {
            release();
        }
    }

    /**
     * Subscribe to the given list of topics to get dynamically assigned partitions. However OKafka 0.8 supports 
     * only subscription to single topic and only one partition is assigned dynamically to consumer. Consumer fetches
     * messages from this partition for its lifetime. If consumer goes down then messages from this partition remains 
     * unconsumed. Client has to start a new consumer to consume from this partition.
     * 
     * <b>
     * Topic subscriptions are not incremental. This list will replace the current
     * assignment (if there is one).
     * </b> .
     *
     * If the given list of topics is empty, it is treated the same as {@link #unsubscribe()}.
     * This call has effect only when poll is invoked.
     * <p>
     * This is a short-hand for {@link #subscribe(Collection, ConsumerRebalanceListener)}, which
     * uses a no-op listener. okafka 0.8 doesn't support consumer group rebalance listener i.e. <b>ConsumerRebalanceListener</b>.
     *
     * @param topics The list of topics to subscribe to
     * @throws IllegalArgumentException If topics is null or contains null or empty elements or size of topics is greater than one.
     */
    @Override
    public void subscribe(Collection<String> topics) {
        subscribe(topics, new NoOpConsumerRebalanceListener());
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void subscribe(Pattern pattern, ConsumerRebalanceListener listener) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void subscribe(Pattern pattern) {
        subscribe(pattern, new NoOpConsumerRebalanceListener());
    }

    /**
     * Unsubscribe from topic currently subscribed with {@link #subscribe(Collection)}.
     */
    public void unsubscribe() {
    	acquireAndEnsureOpen();
        try {
            log.debug("Unsubscribed to all topics ");
            this.subscriptions.unsubscribe();
            this.client.clearSubscription();
            this.client.unsubscribe();
            this.metadata.needMetadataForAllTopics(false);
        } finally {
            release();
        }
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void assign(Collection<TopicPartition> partitions) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * Fetch data for the topic specified using {@link #subscribe(Collection)}  APIs. It is an error to not have
     * subscribed to any topic before polling for data Consumer maintains a single connection/session to any one of the oracle database instance. Each consumer(session )in a group is assigned a single unique partition of subscribed topic.
     * Hence, Poll fetches data from its assigned partition till connection/session exists. If existing connection lost and  connected to any instance of database then consumer(session) might be assigned with new partition of subscribed topic.
     * <p>
     * On each poll consumer tries to fetch from last consumed message id(offset). If consumer goes down without commiting then all consumed messages are rolled back.
     * and next consumer instance of same group who got this partition starts consuming from last committed msgid or from rolled back point. 
     * 
     * As of 0.8 okafka, there is no group balancing since each instance sticks with its partition.
     * 
     * @param timeout The time, in milliseconds, spent waiting in poll.
     * @return map of topic to records since the last fetch for the subscribed list of topic.
     *
     * @throws KafkaException for any other unrecoverable errors (e.g. errors deserializing key/value pairs,
     * or any new error cases in future versions)
     * @throws IllegalArgumentException if the timeout value is negative
     * @throws IllegalStateException if the consumer is not subscribed to any topic.
     *
     */
    @Deprecated
    @Override
    public ConsumerRecords<K, V> poll(final long timeout) {
        return poll(timeout, false);
    }

    /**
     * Fetch data for the topic specified using {@link #subscribe(Collection)}  APIs. It is an error to not have
     * subscribed to any topic before polling for data. Each consumer(session )in a group is assigned a single unique partition of subscribed topic.
     * Hence, Poll fetches data from its assigned partition till connection/session exists. If existing connection lost and  connected to any instance of database then consumer(session) might be assigned with new partition of subscribed topic.
     * <p>
     * On each poll, consumer will try to use the last consumed offset as the starting offset and fetch sequentially. 
     * 
     * @param timeout The time, in milliseconds, spent waiting in poll.
     * @return map of topic to records since the last fetch for the subscribed list of topic.
     *
     * @throws KafkaException for any other unrecoverable errors (e.g. errors deserializing key/value pairs)
     * @throws IllegalArgumentException if the timeout value is negative
     * @throws IllegalStateException if the consumer is not subscribed to any topic.
     * @throws ArithmeticException if the timeout is greater than
	 *         {@link Long#MAX_VALUE} milliseconds.
     *
     */
    @Override
    public ConsumerRecords<K, V> poll(final Duration timeout) {
        return poll(timeout.toMillis(), true);
    }

    private ConsumerRecords<K, V> poll(final long timeoutMs, final boolean includeMetadataInTimeout) {
        acquireAndEnsureOpen();
        try {
            if (timeoutMs < 0) throw new IllegalArgumentException("Timeout must not be negative");

            if (this.subscriptions.hasNoSubscription()) {
                throw new IllegalStateException("Consumer is not subscribed to any topics or assigned any partitions");
            }

            // poll for new data until the timeout expires
            long elapsedTime = 0L;
            final long metadataEnd;
            if(includeMetadataInTimeout) {
            	final long metadataStart = time.milliseconds();
                log.debug("KafkaConsumer: metadataStart {}", metadataStart);
                log.debug("KafkaConsumer: remainingTimeAtLeastZero {}", remainingTimeAtLeastZero(timeoutMs, elapsedTime));

                if (!updateMetadataAndSubscribeIfNeeded(remainingTimeAtLeastZero(timeoutMs, elapsedTime))) {
                    return ConsumerRecords.empty();
                }

                metadataEnd = time.milliseconds();

                log.debug("KafkaConsumer: metadataEnd {}", metadataEnd);

                elapsedTime += metadataEnd - metadataStart;

                log.debug("KafkaConsumer: elapsedTime {}", elapsedTime);


            } else {
            	while(!updateMetadataAndSubscribeIfNeeded(Long.MAX_VALUE)) {
                    log.warn("Still waiting for metadata");
            	}

            	 metadataEnd = time.milliseconds();
            }
            

            final long syncStart = time.milliseconds();
            client.maybeAutoCommitOffsetsSync(time.milliseconds());
            final long syncEnd = time.milliseconds();
            elapsedTime += syncStart - syncEnd;
          //final long fetchStart = time.milliseconds();

            log.debug("KafkaConsumer: elapsedTime {} after syncStart {} - syncEnd {}", elapsedTime, syncStart, syncEnd);

            final Map<TopicPartition, List<ConsumerRecord<K, V>>> records = pollForFetches(remainingTimeAtLeastZero(timeoutMs, elapsedTime));

            if (!records.isEmpty()) {

                return this.interceptors.onConsume(new ConsumerRecords<>(records));
            }

            //final long fetchEnd = time.milliseconds();
            //elapsedTime += fetchEnd - fetchStart;  
            return ConsumerRecords.empty();
         } catch(InvalidLoginCredentialsException exception) {
			 log.error(exception.getMessage());
			 log.info("Closing the consumer");
	       	 close();
        	 throw new AuthenticationException(exception.getMessage());
         } finally {
            release(); 
        }
    }

    private boolean updateMetadataAndSubscribeIfNeeded(long timeout)  {
    	long elapsed = 0L;
    	long subscriptionStart = time.milliseconds();
         if( !client.mayBeTriggerSubcription(timeout)) {
        	 return false;
         }
    
         elapsed += time.milliseconds() - subscriptionStart;
         if(elapsed <= timeout) {
        	 Set<TopicPartition> partitions = subscriptions.partitionsNeedingReset(time.milliseconds());
             if (partitions.isEmpty())
                 return true;
             
             final Map<TopicPartition, Long> offsetResetTimestamps = new HashMap<>();
             for (final TopicPartition partition : partitions) {
                 Long timestamp = offsetResetStrategyTimestamp(partition);
                 if (timestamp != null)
                     offsetResetTimestamps.put(partition, timestamp);
             }
            
             return client.resetOffsetsSync(offsetResetTimestamps, timeout - elapsed); 
         }
          return true;
    }

    private Map<TopicPartition, List<ConsumerRecord<K, V>>> pollForFetches(final long timeoutMs) {
    	if(timeoutMs <= 0) return Collections.<TopicPartition, List<ConsumerRecord<K, V>>>emptyMap();
        return createConsumerRecordsMap(client.poll(timeoutMs));
    }
    
    private Map<TopicPartition, List<ConsumerRecord<K, V>>> createConsumerRecordsMap(List<AQjmsBytesMessage> messages)  {
    	if(messages.size() == 0 ) return Collections.<TopicPartition, List<ConsumerRecord<K, V>>>emptyMap();
    	
    	Map<TopicPartition, List<ConsumerRecord<K, V>>> consumerRecords = new HashMap<>();
        ConsumerRecord<K, V> record;
    	String topic = null;
    	int partition = -1;
        for(AQjmsBytesMessage message : messages) {           
       	try {
          	 byte[] valueByteArray = message.getBytesData(); 
          	 byte[] keyByteArray = message.getJMSCorrelationIDAsBytes();
          	 topic = message.getStringProperty("topic");
          	 partition = message.getIntProperty("AQINTERNAL_PARTITION")/2;
          	 K key = this.keyDeserializer.deserialize(message.getStringProperty("topic"), keyByteArray);
          	 V value = this.valueDeserializer.deserialize(message.getStringProperty("topic"), valueByteArray);
         
          	 record = new ConsumerRecord<>(topic, partition, MessageIdConverter.getOffset(message.getJMSMessageID()),
                                           message.getJMSTimestamp(), TimestampType.LOG_APPEND_TIME, null, valueByteArray.length == 0 ? ConsumerRecord.NULL_SIZE : valueByteArray.length,
                                           valueByteArray.length == 0 ? ConsumerRecord.NULL_SIZE : valueByteArray.length,
                                           		key, value, new RecordHeaders());
       	} catch(JMSException exception) {
       		record = new ConsumerRecord<>("", -1, -1, -1, TimestampType.NO_TIMESTAMP_TYPE, null, ConsumerRecord.NULL_SIZE, 
       				ConsumerRecord.NULL_SIZE, null, null, new RecordHeaders());
       	}
       	TopicPartition tp = new TopicPartition(topic, partition);
       	if(tp != null && partition != -1) {
       		OffsetAndMetadata offset = subscriptions.allConsumed().get(tp);
           	if(offset == null) 
           		subscriptions.allConsumed().put(tp , new OffsetAndMetadata(record.offset()));
           	else {
           		if(offset.offset() < record.offset()) 
           			subscriptions.allConsumed().put(tp , new OffsetAndMetadata(record.offset()));
           	}
       	}
       		
       	if(!consumerRecords.containsKey(tp)) 
       		consumerRecords.put(tp, new ArrayList<ConsumerRecord<K,V>>());
       	consumerRecords.get(tp).add(record);
       	
        }	
    return consumerRecords;
    }
    	 

    private long remainingTimeAtLeastZero(final long timeoutMs, final long elapsedTime) {
        return Math.max(0, timeoutMs - elapsedTime);
    }

    /**
     * Commits messages(offsets) consumed using {@link #poll(Duration) poll()} since last commit in this session.
     * 
     * Commit on session is either successfull or rollback. Commit fails only in rare cases like shutdown. Commit failure results in rollback.
     * If rollback occurs then consumed messages since last commit are considered not consumed.
     * If process restarts after failure then it starts consuming from this position.
     * <p>
     * This is a synchronous commit and will block until either the commit succeeds or rollback happens. 
     * Commit does not take any timeout into account for completion of call.
     * <p>
     *
     * @throws KafkaException for any other unrecoverable errors (i.e topic doesn't exist, session rolled back as db shutdown).
     */
    @Override
    public void commitSync() {
        commitSync(Duration.ofMillis(defaultApiTimeoutMs));
    }

    /**
    * Commits messages(offsets) consumed using {@link #poll(Duration) poll()} since last commit in this session.
    * 
    * Commit on session is either successfull or rollback. Commit fails only in rare cases like shutdown. Commit failure results in rollback.
    * If rollback occurs then consumed messages since last commit are considered not consumed.
    * If process restarts after failure then it starts consuming from this position.
    * <p>
    * This is a synchronous commit and will block until either the commit succeeds or rollback happens. 
    * Commit does not take any timeout into account for completion of call. This call is equivalent to commitSync().
    * <p>
    *
    * @throws KafkaException for any other unrecoverable errors .
    */
    @Override
    public void commitSync(Duration timeout) {
        acquireAndEnsureOpen();
        
        try {
            client.commitOffsetsSync(subscriptions.allConsumed(), timeout.toMillis());
            interceptors.onCommit(this.subscriptions.allConsumed());
        } catch (Exception exception) {
        	throw new KafkaException("failed to commit messages", exception);
        } finally {
            release();
        }
    }

    /**
     * This method not yet supported.
     */
    @Override
    public void commitSync(final Map<TopicPartition, OffsetAndMetadata> offsets) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
    * This method not yet supported.
    */
    @Override
    public void commitSync(final Map<TopicPartition, OffsetAndMetadata> offsets, final Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release."); 
    }

    /**
     * Commit mesages consumed using {@link #poll(Duration)} for the subscribed topic and assigned partition in this session since last commit.
     * This call is equivalent to {@link #commitAsync(OffsetCommitCallback)} with null callback.
     */
    @Override
    public void commitAsync() {
        commitAsync(null);
    }

    /**
     * Commits messages(offsets) consumed using {@link #poll(Duration) )} since last commit in this session.
     * 
     * Commit on session is either successfull or rollback. Commit fails only in rare cases like shutdown. Commit failure results in rollback.
     * If rollback occurs then consumed messages since last commit are considered not consumed.
     * If process restarts after failure then it starts consuming from this rollback position.
     * <p>
     * Internally this is an  synchronous call and blocks until either commit is successful or rolled back. Any errors encountered are either passed to the callback
     * (if provided) or discarded.
     * <p>
     * @param callback Callback to invoke when the commit completes
     */
    @Override
    public void commitAsync(OffsetCommitCallback callback) {
    	try {
    		client.commitOffsetsSync(subscriptions.allConsumed(), defaultApiTimeoutMs);
    		if(callback!= null)
        		callback.onComplete(this.subscriptions.allConsumed(), null);
    	} catch( Exception exception) {
    		if(callback !=null)
    		    callback.onComplete(this.subscriptions.allConsumed(), new KafkaException("failed to commit the current consumed offsets", exception));
    	}
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void commitAsync(final Map<TopicPartition, OffsetAndMetadata> offsets, OffsetCommitCallback callback) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * Overrides the fetch offset that the consumer will use on the next
	 * {@link #poll(Duration) poll(timeout)}. If this API is invoked for the same
	 * partition more than once, the latest offset will be used on the next poll().
	 * Seeking to already consumed offset/message ,
	 * in current or previous sessions, doesn't reconsume the message.
	 *
	 * @throws IllegalArgumentException if the provided offset is negative
     */
     // @throws IllegalStateException    if the provided TopicPartition is not
	 //                                  assigned to this consumer
    @Override
    public void seek(TopicPartition partition, long offset) {
    	if (offset < 0)
			throw new IllegalArgumentException("seek offset must not be a negative number");

		acquireAndEnsureOpen();
		try {
			log.debug("Seeking to offset {} for partition {}", offset, partition);
			this.subscriptions.seek(partition, offset);
		} finally {
			release();
		}
    }

    /**
     * Seek to the first available offset for each of the given partitions. This function
	 * evaluates lazily, seeking to the first offset in all partitions only when
	 * {@link #poll(Duration)}  is called.
	 * Seeking to already consumed offset/message ,
	 * in current or previous sessions, doesn't reconsume the message.
	 *
	 * @throws IllegalArgumentException if {@code partitions} is {@code null}
     */
     // @throws IllegalStateException    if the provided TopicPartition is not
 	 //                                  assigned to this consumer

    @Override
    public void seekToBeginning(Collection<TopicPartition> partitions) {
    	if (partitions == null)
			throw new IllegalArgumentException("Partitions collection cannot be null");

		acquireAndEnsureOpen();
		try {
			Collection<TopicPartition> parts = partitions.size() == 0 ? this.subscriptions.assignedPartitions()
					: partitions;
			for (TopicPartition tp : parts) {
				log.debug("Seeking to beginning of partition {}", tp);
				subscriptions.requestOffsetReset(tp, OffsetResetStrategy.EARLIEST);
			}
		} finally {
			release();
		}
    }

    /**
     * Seek to the last offset for each of the given partitions. This function
	 * evaluates lazily, seeking to the final offset in all partitions only when
	 * {@link #poll(Duration)} is called.
	 * Seeking to already consumed offset/message ,
	 * in current or previous sessions, doesn't reconsume the message.
	 *
	 * @throws IllegalArgumentException if {@code partitions} is {@code null}
     */
     // @throws IllegalStateException    if the provided TopicPartition is not
 	 //                                  assigned to this consumer

    @Override
    public void seekToEnd(Collection<TopicPartition> partitions) {
    	if (partitions == null)
			throw new IllegalArgumentException("Partitions collection cannot be null");

		acquireAndEnsureOpen();
		try {
			Collection<TopicPartition> parts = partitions.size() == 0 ? this.subscriptions.assignedPartitions()
					: partitions;
			for (TopicPartition tp : parts) {
				log.debug("Seeking to end of partition {}", tp);
				subscriptions.requestOffsetReset(tp, OffsetResetStrategy.LATEST);
			}
		} finally {
			release();
		}
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public long position(TopicPartition partition) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public long position(TopicPartition partition, final Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public OffsetAndMetadata committed(TopicPartition partition) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public OffsetAndMetadata committed(TopicPartition partition, final Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<MetricName, ? extends Metric> metrics() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public List<PartitionInfo> partitionsFor(String topic) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public List<PartitionInfo> partitionsFor(String topic, Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<String, List<PartitionInfo>> listTopics() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<String, List<PartitionInfo>> listTopics(Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void pause(Collection<TopicPartition> partitions) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void resume(Collection<TopicPartition> partitions) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Set<TopicPartition> paused() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, OffsetAndTimestamp> offsetsForTimes(Map<TopicPartition, Long> timestampsToSearch) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, OffsetAndTimestamp> offsetsForTimes(Map<TopicPartition, Long> timestampsToSearch, Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, Long> beginningOffsets(Collection<TopicPartition> partitions) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, Long> beginningOffsets(Collection<TopicPartition> partitions, Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, Long> endOffsets(Collection<TopicPartition> partitions) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public Map<TopicPartition, Long> endOffsets(Collection<TopicPartition> partitions, Duration timeout) {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");     
    }

    /**
     * Tries to close the consumer cleanly.
     * If auto-commit is enabled, this will commit the current offsets . Close doen't take timeout into consideration.
     *
     * @throws KafkaException for any other error during close
     */
    @Override
    public void close() {
        close(Duration.ofMillis(DEFAULT_CLOSE_TIMEOUT_MS));
    }

    /**
     * Tries to close the consumer cleanly.
     * If auto-commit is enabled, this will commit the current offsets . Close doen't take timeout into consideration.
     * 
     * @param timeout  Not used
     * @param timeUnit Not used
     * @throws IllegalArgumentException If the {@code timeout} is negative.
     * @throws KafkaException for any other error during close
     *
     */
    @Deprecated
    @Override
    public void close(long timeout, TimeUnit timeUnit) {
        close(Duration.ofMillis(timeUnit.toMillis(timeout)));
    }

    /**
     * Tries to close the consumer cleanly.
     * If auto-commit is enabled, this will commit the current offsets . Close doen't take timeout into consideration.
     *
     * @param timeout not used
     *
     * @throws IllegalArgumentException If the {@code timeout} is negative.
     * @throws KafkaException for any other error during close
     */
    @Override
    public void close(Duration timeout) {
        if (timeout.toMillis() < 0)
            throw new IllegalArgumentException("The timeout cannot be negative.");
        acquire();
        try {
            if (!closed) {
                closed = true;
                close(timeout.toMillis(), false);
            }
        } finally {
            release();
        }
    }

    /**
     * This method is not yet supported.
     */
    @Override
    public void wakeup() {
    	throw new FeatureNotSupportedException("This feature is not suported for this release.");
    }

    private ClusterResourceListeners configureClusterResourceListeners(Deserializer<K> keyDeserializer, Deserializer<V> valueDeserializer, List<?>... candidateLists) {
        ClusterResourceListeners clusterResourceListeners = new ClusterResourceListeners();
        for (List<?> candidateList: candidateLists)
            clusterResourceListeners.maybeAddAll(candidateList);

        clusterResourceListeners.maybeAdd(keyDeserializer);
        clusterResourceListeners.maybeAdd(valueDeserializer);
        return clusterResourceListeners;
    }

    private void close(long timeoutMs, boolean swallowException) {
        log.trace("Closing the Kafka consumer");
        AtomicReference<Throwable> firstException = new AtomicReference<>();
        try {
            if (client != null)
                client.close(Math.min(timeoutMs, requestTimeoutMs));
        } catch (Throwable t) {
            firstException.compareAndSet(null, t);
            log.error("Failed to close OKafka consumer ", t);
        }
        ClientUtils.closeQuietly(interceptors, "consumer interceptors", firstException);
        ClientUtils.closeQuietly(metrics, "consumer metrics", firstException);
        ClientUtils.closeQuietly(keyDeserializer, "consumer key deserializer", firstException);
        ClientUtils.closeQuietly(valueDeserializer, "consumer value deserializer", firstException);
        AppInfoParser.unregisterAppInfo(JMX_PREFIX, clientId, metrics);
        log.debug("Kafka consumer has been closed");
        Throwable exception = firstException.get();
        if (exception != null && !swallowException) {
            throw new KafkaException("Failed to close kafka consumer", exception);
        }
    }
    
    private Long offsetResetStrategyTimestamp(final TopicPartition partition) {
        OffsetResetStrategy strategy = subscriptions.resetStrategy(partition);
        if (strategy == OffsetResetStrategy.EARLIEST)
            return -2L;
        else if (strategy == OffsetResetStrategy.LATEST)
            return -1L;
        else if (strategy == OffsetResetStrategy.TO_OFFSET)
        	return subscriptions.position(partition);
        else
            return null;
    }

    /**
     * Acquire the light lock and ensure that the consumer hasn't been closed.
     * @throws IllegalStateException If the consumer has been closed
     */
    private void acquireAndEnsureOpen() {
        acquire();
        if (this.closed) {
            release();
            throw new IllegalStateException("This consumer has already been closed.");
        }
    }

    /**
     * Acquire the light lock protecting this consumer from multi-threaded access. Instead of blocking
     * when the lock is not available, however, we just throw an exception (since multi-threaded usage is not
     * supported).
     * @throws ConcurrentModificationException if another thread already has the lock
     */
    private void acquire() {
        long threadId = Thread.currentThread().getId();
        if (threadId != currentThread.get() && !currentThread.compareAndSet(NO_CURRENT_THREAD, threadId))
            throw new ConcurrentModificationException("KafkaConsumer is not safe for multi-threaded access");
        refcount.incrementAndGet();
    }

    /**
     * Release the light lock protecting the consumer from multi-threaded access.
     */
    private void release() {
        if (refcount.decrementAndGet() == 0)
            currentThread.set(NO_CURRENT_THREAD);
    }
}
