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

package org.oracle.okafka.clients.producer;

//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.extension.ExtendWith;
import org.oracle.okafka.clients.Metadata;
import org.oracle.okafka.clients.MockClient;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.errors.InterruptException;
import org.oracle.okafka.common.errors.TimeoutException;
import org.oracle.okafka.common.internals.ClusterResourceListeners;
import org.oracle.okafka.common.serialization.ByteArraySerializer;
import org.oracle.okafka.common.serialization.StringSerializer;
import org.oracle.okafka.common.utils.MockTime;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.test.*;
import org.powermock.api.support.membermodification.MemberModifier;
import org.powermock.core.classloader.annotations.PowerMockIgnore;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

//import static org.junit.jupiter.api.Assertions.*;


import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.powermock.modules.junit4.PowerMockRunner;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;


@RunWith(PowerMockRunner.class)
//@ExtendWith(PowerMockExtension.class)
@PowerMockIgnore("javax.management.*")
public class KafkaProducerTest {

    @Test
    public void testConstructorWithSerializers() {
        Properties producerProps = new Properties();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9000");
        producerProps.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        producerProps.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        producerProps.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        new KafkaProducer<>(producerProps, new ByteArraySerializer(), new ByteArraySerializer()).close();
    }

    //@Test(expected = ConfigException.class)
    @Test
    public void testNoSerializerProvided() {
        Properties producerProps = new Properties();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9000");
        producerProps.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        producerProps.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        producerProps.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        new KafkaProducer(producerProps);
    }
    

    @Test
    public void testConstructorFailureCloseResource() {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.CLIENT_ID_CONFIG, "testConstructorClose");
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "some.invalid.hostname.foo.bar.local:9999");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        props.setProperty(ProducerConfig.METRIC_REPORTER_CLASSES_CONFIG, MockMetricsReporter.class.getName());

        final int oldInitCount = MockMetricsReporter.INIT_COUNT.get();
        final int oldCloseCount = MockMetricsReporter.CLOSE_COUNT.get();
        try (KafkaProducer<byte[], byte[]> producer = new KafkaProducer<>(props, new ByteArraySerializer(), new ByteArraySerializer())) {
            fail("should have caught an exception and returned");
        } catch (KafkaException e) {
            assertEquals(oldInitCount + 1, MockMetricsReporter.INIT_COUNT.get());
            assertEquals(oldCloseCount + 1, MockMetricsReporter.CLOSE_COUNT.get());
            assertEquals("Failed to construct kafka producer", e.getMessage());
        }
    }

    @Test
    public void testSerializerClose() throws Exception {
        Map<String, Object> configs = new HashMap<>();
        configs.put(ProducerConfig.CLIENT_ID_CONFIG, "testConstructorClose");
        configs.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
        configs.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        configs.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        configs.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/tmp");
        configs.put(ProducerConfig.METRIC_REPORTER_CLASSES_CONFIG, MockMetricsReporter.class.getName());
        final int oldInitCount = MockSerializer.INIT_COUNT.get();
        final int oldCloseCount = MockSerializer.CLOSE_COUNT.get();

        KafkaProducer<byte[], byte[]> producer = new KafkaProducer<byte[], byte[]>(
                configs, new MockSerializer(), new MockSerializer());
        assertEquals(oldInitCount + 2, MockSerializer.INIT_COUNT.get());
        assertEquals(oldCloseCount, MockSerializer.CLOSE_COUNT.get());

        producer.close();
        assertEquals(oldInitCount + 2, MockSerializer.INIT_COUNT.get());
        assertEquals(oldCloseCount + 2, MockSerializer.CLOSE_COUNT.get());
    }

    @Test
    public void testInterceptorConstructClose() throws Exception {
        try {
            Properties props = new Properties();
            // test with client ID assigned by KafkaProducer
            props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
            props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
            props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
            props.setProperty(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, MockProducerInterceptor.class.getName());
            props.setProperty(MockProducerInterceptor.APPEND_STRING_PROP, "something");

            KafkaProducer<String, String> producer = new KafkaProducer<String, String>(
                    props, new StringSerializer(), new StringSerializer());
            assertEquals(1, MockProducerInterceptor.INIT_COUNT.get());
            assertEquals(0, MockProducerInterceptor.CLOSE_COUNT.get());

            // Cluster metadata will only be updated on calling onSend.
            Assert.assertNull(MockProducerInterceptor.CLUSTER_META.get());
            //assertNull(MockProducerInterceptor.CLUSTER_META.get());

            producer.close();
            assertEquals(1, MockProducerInterceptor.INIT_COUNT.get());
            assertEquals(1, MockProducerInterceptor.CLOSE_COUNT.get());
        } finally {
            // cleanup since we are using mutable static variables in MockProducerInterceptor
            MockProducerInterceptor.resetCounters();
        }
    }

    @Test
    public void testPartitionerClose() throws Exception {
        try {
            Properties props = new Properties();
            props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
            props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
            props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
            MockPartitioner.resetCounters();
            props.setProperty(ProducerConfig.PARTITIONER_CLASS_CONFIG, MockPartitioner.class.getName());

            KafkaProducer<String, String> producer = new KafkaProducer<String, String>(
                    props, new StringSerializer(), new StringSerializer());
            assertEquals(1, MockPartitioner.INIT_COUNT.get());
            assertEquals(0, MockPartitioner.CLOSE_COUNT.get());

            producer.close();
            assertEquals(1, MockPartitioner.INIT_COUNT.get());
            assertEquals(1, MockPartitioner.CLOSE_COUNT.get());
        } finally {
            // cleanup since we are using mutable static variables in MockPartitioner
            MockPartitioner.resetCounters();
        }
    }

    @Test
    public void shouldCloseProperlyAndThrowIfInterrupted() throws Exception {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        props.setProperty(ProducerConfig.PARTITIONER_CLASS_CONFIG, MockPartitioner.class.getName());
        props.setProperty(ProducerConfig.BATCH_SIZE_CONFIG, "1");

        Time time = new MockTime();
        Cluster cluster = TestUtils.singletonCluster("topic", 1);
        Node node = cluster.nodes().get(0);

        Metadata metadata = new Metadata(0, Long.MAX_VALUE, true, null);
        metadata.update(cluster, Collections.<String>emptySet(), time.milliseconds());
        
        MockClient client = new MockClient(time, metadata);
        client.setNode(node);

        final Producer<String, String> producer = new KafkaProducer<>(
            new ProducerConfig(ProducerConfig.addSerializerToConfig(props, new StringSerializer(), new StringSerializer())),
            new StringSerializer(), new StringSerializer(), metadata, client);

        ExecutorService executor = Executors.newSingleThreadExecutor();
        final AtomicReference<Exception> closeException = new AtomicReference<>();
        try {
            Future<?> future = executor.submit(new Runnable() {
                @Override
                public void run() {
                    producer.send(new ProducerRecord<>("topic", "key", "value"));
                    try {
                        producer.close();
                        fail("Close should block and throw.");
                    } catch (Exception e) {
                        closeException.set(e);
                    }
                }
            });

            // Close producer should not complete until send succeeds
            try {
                future.get(100, TimeUnit.MILLISECONDS);
                fail("Close completed without waiting for send");
            } catch (java.util.concurrent.TimeoutException expected) {  }

            // Ensure send has started
            //client.waitForRequests(1, 1000);

            //assertTrue("Close terminated prematurely", future.cancel(true));
            assertTrue("Close terminated prematurely", future.cancel(true));

            TestUtils.waitForCondition(new TestCondition() {
                @Override
                public boolean conditionMet() {
                    return closeException.get() != null;
                }
            }, "InterruptException did not occur within timeout.");

            //assertTrue("Expected exception not thrown " + closeException, closeException.get() instanceof InterruptException);
            assertTrue("Expected exception not thrown " + closeException, closeException.get() instanceof InterruptException);
        } finally {
            executor.shutdownNow();
        }

    }
/*
    @PrepareOnlyThisForTest(Metadata.class)
    @Test
    public void testMetadataFetch() throws Exception {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:1521");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "serviceid.regress.rdbms.dev.us.oracle.com");
        KafkaProducer<String, String> producer = new KafkaProducer<>(props, new StringSerializer(), new StringSerializer());
        Metadata metadata = PowerMock.createNiceMock(Metadata.class);
        MemberModifier.field(KafkaProducer.class, "metadata").set(producer, metadata);

        String topic = "topic";
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, "value");
        Collection<Node> nodes = Collections.singletonList(new Node(0, "host1", 1000, "", ""));
        final Cluster emptyCluster = new Cluster(null, nodes,
                Collections.<PartitionInfo>emptySet(),
                Collections.<String>emptySet(),
                Collections.<String>emptySet(), null);
        final Cluster cluster = new Cluster(
                "dummy",
                Collections.singletonList(new Node(0, "host1", 1000, "", "")),
                Arrays.asList(new PartitionInfo(topic, 0, null, null, null)),
                Collections.<String>emptySet(),
                Collections.<String>emptySet(), null);

        // Expect exactly one fetch for each attempt to refresh while topic metadata is not available
        final int refreshAttempts = 5;
        EasyMock.expect(metadata.fetch()).andReturn(emptyCluster).times(refreshAttempts - 1);
        EasyMock.expect(metadata.fetch()).andReturn(cluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.send(record);
        PowerMock.verify(metadata);

        // Expect exactly one fetch if topic metadata is available
        PowerMock.reset(metadata);
        EasyMock.expect(metadata.fetch()).andReturn(cluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.send(record, null);
        PowerMock.verify(metadata);

        // Expect exactly one fetch if topic metadata is available
        PowerMock.reset(metadata);
        EasyMock.expect(metadata.fetch()).andReturn(cluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.partitionsFor(topic);
        PowerMock.verify(metadata);
    }

    @PrepareOnlyThisForTest(Metadata.class)
    @Test
    public void testMetadataFetchOnStaleMetadata() throws Exception {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
          props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        KafkaProducer<String, String> producer = new KafkaProducer<>(props, new StringSerializer(), new StringSerializer());
        Metadata metadata = PowerMock.createNiceMock(Metadata.class);
        MemberModifier.field(KafkaProducer.class, "metadata").set(producer, metadata);

        String topic = "topic";
        ProducerRecord<String, String> initialRecord = new ProducerRecord<>(topic, "value");
        // Create a record with a partition higher than the initial (outdated) partition range
        ProducerRecord<String, String> extendedRecord = new ProducerRecord<>(topic, 2, null, "value");
        Collection<Node> nodes = Collections.singletonList(new Node(0, "host1", 1000, "", ""));
        final Cluster emptyCluster = new Cluster(null, nodes,
                Collections.<PartitionInfo>emptySet(),
                Collections.<String>emptySet(),
                Collections.<String>emptySet(), null);
        final Cluster initialCluster = new Cluster(
                "dummy",
                Collections.singletonList(new Node(0, "host1", 1000, "", "")),
                Arrays.asList(new PartitionInfo(topic, 0, null, null, null)),
                Collections.<String>emptySet(),
                Collections.<String>emptySet(), null);
        final Cluster extendedCluster = new Cluster(
                "dummy",
                Collections.singletonList(new Node(0, "host1", 1000, "", "")),
                Arrays.asList(
                        new PartitionInfo(topic, 0, null, null, null),
                        new PartitionInfo(topic, 1, null, null, null),
                        new PartitionInfo(topic, 2, null, null, null)),
                Collections.<String>emptySet(),
                Collections.<String>emptySet(), null);

        // Expect exactly one fetch for each attempt to refresh while topic metadata is not available
        final int refreshAttempts = 5;
        EasyMock.expect(metadata.fetch()).andReturn(emptyCluster).times(refreshAttempts - 1);
        EasyMock.expect(metadata.fetch()).andReturn(initialCluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.send(initialRecord);
        PowerMock.verify(metadata);

        // Expect exactly one fetch if topic metadata is available and records are still within range
        PowerMock.reset(metadata);
        EasyMock.expect(metadata.fetch()).andReturn(initialCluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.send(initialRecord, null);
        PowerMock.verify(metadata);

        // Expect exactly two fetches if topic metadata is available but metadata response still returns
        // the same partition size (either because metadata are still stale at the broker too or because
        // there weren't any partitions added in the first place).
        PowerMock.reset(metadata);
        EasyMock.expect(metadata.fetch()).andReturn(initialCluster).once();
        EasyMock.expect(metadata.fetch()).andReturn(initialCluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        try {
            producer.send(extendedRecord, null);
            fail("Expected KafkaException to be raised");
        } catch (KafkaException e) {
            // expected
        }
        PowerMock.verify(metadata);

        // Expect exactly two fetches if topic metadata is available but outdated for the given record
        PowerMock.reset(metadata);
        EasyMock.expect(metadata.fetch()).andReturn(initialCluster).once();
        EasyMock.expect(metadata.fetch()).andReturn(extendedCluster).once();
        EasyMock.expect(metadata.fetch()).andThrow(new IllegalStateException("Unexpected call to metadata.fetch()")).anyTimes();
        PowerMock.replay(metadata);
        producer.send(extendedRecord, null);
        PowerMock.verify(metadata);
    }
*/
    @Test
    public void testTopicRefreshInMetadata() throws Exception {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        props.setProperty(ProducerConfig.MAX_BLOCK_MS_CONFIG, "600000");
        KafkaProducer<String, String> producer = new KafkaProducer<>(props, new StringSerializer(), new StringSerializer());
        long refreshBackoffMs = 500L;
        long metadataExpireMs = 60000L;
        final Metadata metadata = new Metadata(refreshBackoffMs, metadataExpireMs, true,
                true, new ClusterResourceListeners(), null);
        final Time time = new MockTime();
        MemberModifier.field(KafkaProducer.class, "metadata").set(producer, metadata);
        MemberModifier.field(KafkaProducer.class, "time").set(producer, time);
        final String topic = "topic";

        Thread t = new Thread() {
            @Override
            public void run() {
                long startTimeMs = System.currentTimeMillis();
                for (int i = 0; i < 10; i++) {
                    while (!metadata.updateRequested() && System.currentTimeMillis() - startTimeMs < 1000)
                        yield();
                    metadata.update(Cluster.empty(), Collections.singleton(topic), time.milliseconds());
                    time.sleep(60 * 1000L);
                }
            }
        };
        t.start();
        try {
            producer.partitionsFor(topic);
            fail("Expect TimeoutException");
        } catch (TimeoutException e) {
            // skip
        }
        Assert.assertTrue("Topic should still exist in metadata", metadata.containsTopic(topic));
    }
	
    @Test
    public void closeShouldBeIdempotent() {
        Properties producerProps = new Properties();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9000");
        producerProps.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        producerProps.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        producerProps.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        Producer producer = new KafkaProducer<>(producerProps, new ByteArraySerializer(), new ByteArraySerializer());
        producer.close();
        producer.close();
    }

   /* @PrepareOnlyThisForTest(Metadata.class)
    @Test
    public void testInterceptorPartitionSetOnTooLargeRecord() throws Exception {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9999");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
            props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        props.setProperty(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, "1");
        String topic = "topic";
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, "value");

        KafkaProducer<String, String> producer = new KafkaProducer<>(props, new StringSerializer(),
                new StringSerializer());
        Metadata metadata = PowerMock.createNiceMock(Metadata.class);
        MemberModifier.field(KafkaProducer.class, "metadata").set(producer, metadata);
        final Cluster cluster = new Cluster(
            "dummy",
            Collections.singletonList(new Node(0, "host1", 1000, "", "")),
            Arrays.asList(new PartitionInfo(topic, 0, null, null, null)),
            Collections.<String>emptySet(),
            Collections.<String>emptySet(), null);
        EasyMock.expect(metadata.fetch()).andReturn(cluster).once();

        // Mock interceptors field
        ProducerInterceptors interceptors = PowerMock.createMock(ProducerInterceptors.class);
        EasyMock.expect(interceptors.onSend(record)).andReturn(record);
        interceptors.onSendError(EasyMock.eq(record), EasyMock.<TopicPartition>notNull(), EasyMock.<Exception>notNull());
        EasyMock.expectLastCall();
        MemberModifier.field(KafkaProducer.class, "interceptors").set(producer, interceptors);

        PowerMock.replay(metadata);
        EasyMock.replay(interceptors);
        producer.send(record);

        EasyMock.verify(interceptors);
    }
*/
    @Test
    public void testPartitionsForWithNullTopic() {
        Properties props = new Properties();
        props.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9000");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
        try (KafkaProducer<byte[], byte[]> producer = new KafkaProducer<>(props, new ByteArraySerializer(), new ByteArraySerializer())) {
            producer.partitionsFor(null);
            fail("Expected NullPointerException to be raised");
        } catch (NullPointerException e) {
            // expected
        }
    }

    @Test
    public void testCloseWhenWaitingForMetadataUpdate() throws InterruptedException {
        Properties props = new Properties();
        props.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, Long.MAX_VALUE);
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9000");
        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, "instancename");
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, "servicename");
        props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, "/temp");
       
        // Simulate a case where metadata for a particular topic is not available. This will cause KafkaProducer#send to
        // block in Metadata#awaitUpdate for the configured max.block.ms. When close() is invoked, KafkaProducer#send should
        // return with a KafkaException.
        String topicName = "test";
        Time time = new MockTime();
        Cluster cluster = TestUtils.singletonCluster();
        Node node = cluster.nodes().get(0);
        Metadata metadata = new Metadata(0, Long.MAX_VALUE, false, null);
        metadata.update(cluster, Collections.<String>emptySet(), time.milliseconds());

        MockClient client = new MockClient(time, metadata);
        client.setNode(node);
        
        Producer<String, String> producer = new KafkaProducer<>(
                new ProducerConfig(ProducerConfig.addSerializerToConfig(props, new StringSerializer(), new StringSerializer())),
                new StringSerializer(), new StringSerializer(), metadata, client);

        ExecutorService executor = Executors.newSingleThreadExecutor();
        final AtomicReference<Exception> sendException = new AtomicReference<>();
        try {
            executor.submit(() -> {
                try {
                    // Metadata for topic "test" will not be available which will cause us to block indefinitely until
                    // KafkaProducer#close is invoked.
                    producer.send(new ProducerRecord<>(topicName, "key", "value"));
                    fail();
                } catch (Exception e) {
                    sendException.set(e);
                }
            });

            // Wait until metadata update for the topic has been requested
            TestUtils.waitForCondition(() -> metadata.containsTopic(topicName), "Timeout when waiting for topic to be added to metadata");
            producer.close(0, TimeUnit.MILLISECONDS);
            TestUtils.waitForCondition(() -> sendException.get() != null, "No producer exception within timeout");
            assertEquals(KafkaException.class, sendException.get().getClass());
        } finally {
            executor.shutdownNow();
        }
    }

}
