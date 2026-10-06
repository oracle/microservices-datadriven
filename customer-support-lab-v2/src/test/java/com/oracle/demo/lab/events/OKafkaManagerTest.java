// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.KafkaFuture;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.core.task.AsyncTaskExecutor;

import java.util.Collection;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OKafkaManagerTest {
    private final AsyncTaskExecutor executor = mock(AsyncTaskExecutor.class);
    private final Admin admin = mock(Admin.class);
    private final ListTopicsResult topics = mock(ListTopicsResult.class);
    private final TicketEventConsumer consumer = mock(TicketEventConsumer.class);

    @Test
    void existingTopicStartsConsumerWithoutRecreatingIt() {
        when(admin.listTopics()).thenReturn(topics);
        when(topics.names()).thenReturn(KafkaFuture.completedFuture(Set.of("TICKET_EVENT")));

        new OKafkaManager(executor, admin, consumer, "ticket_event").init();

        verify(admin, never()).createTopics(anyCollection());
        verify(executor).submit(consumer);
    }

    @Test
    void missingTopicIsCreatedBeforeConsumerStarts() {
        CreateTopicsResult created = mock(CreateTopicsResult.class);
        when(admin.listTopics()).thenReturn(topics);
        when(topics.names()).thenReturn(KafkaFuture.completedFuture(Set.of()));
        when(admin.createTopics(anyCollection())).thenReturn(created);
        when(created.all()).thenReturn(KafkaFuture.completedFuture(null));

        new OKafkaManager(executor, admin, consumer, "ticket_event").init();

        ArgumentCaptor<Collection<NewTopic>> requested = ArgumentCaptor.forClass(Collection.class);
        verify(admin).createTopics(requested.capture());
        NewTopic topic = requested.getValue().iterator().next();
        assertEquals("ticket_event", topic.name());
        assertEquals((short) 0, topic.replicationFactor());
        verify(executor).submit(consumer);
    }
}
