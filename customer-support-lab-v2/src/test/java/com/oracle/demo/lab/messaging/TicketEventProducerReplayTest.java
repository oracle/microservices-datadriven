// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.messaging.TicketEventProducer;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;
import com.oracle.demo.lab.persistence.TicketStore;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.Test;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import io.micrometer.observation.ObservationRegistry;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;

import java.sql.Connection;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketEventProducerReplayTest {
    @Test
    @SuppressWarnings("unchecked")
    void submissionUsesProducerConnectionForTicketAndEvent() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        Connection connection = mock(Connection.class);
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Lost MFA authenticator");
        ticket.setDescription("How can I recover access safely?");
        when(producer.getDBConnection()).thenReturn(connection);
        when(ticketStore.insert(connection, ticket)).thenReturn(42L);

        long ticketId = new TicketEventProducer(producer, ticketStore,
                mock(TicketEventOutcomeStore.class), spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event")
                .produce(ticket, null);

        ArgumentCaptor<ProducerRecord<String, TicketWorkEvent>> sent = ArgumentCaptor.forClass(ProducerRecord.class);
        InOrder order = inOrder(producer, ticketStore);
        order.verify(producer).beginTransaction();
        order.verify(ticketStore).insert(connection, ticket);
        order.verify(producer).send(sent.capture());
        order.verify(producer).commitTransaction();
        assertEquals(42L, ticketId);
        assertEquals(TicketStatus.RECEIVED, ticket.getWorkflowStatus());
        assertEquals(ticketId, sent.getValue().value().getTicketId());
    }

    @Test
    @SuppressWarnings("unchecked")
    void metricFailureAfterSubmissionCommitDoesNotAbort() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketTelemetry telemetry = spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create()));
        Connection connection = mock(Connection.class);
        SupportTicket ticket = new SupportTicket();
        when(producer.getDBConnection()).thenReturn(connection);
        when(ticketStore.insert(connection, ticket)).thenReturn(42L);
        doThrow(new IllegalStateException("metric exporter unavailable"))
                .when(telemetry).published("submitted");

        long ticketId = new TicketEventProducer(producer, ticketStore,
                mock(TicketEventOutcomeStore.class), telemetry, "ticket_event")
                .produce(ticket, null);

        assertEquals(42L, ticketId);
        verify(producer).commitTransaction();
        verify(producer, never()).abortTransaction();
    }

    @Test
    @SuppressWarnings("unchecked")
    void abortFailureDoesNotMaskOriginalSubmissionError() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        Connection connection = mock(Connection.class);
        SupportTicket ticket = new SupportTicket();
        IllegalStateException insertFailure = new IllegalStateException("insert failed");
        IllegalStateException abortFailure = new IllegalStateException("abort failed");
        when(producer.getDBConnection()).thenReturn(connection);
        when(ticketStore.insert(connection, ticket)).thenThrow(insertFailure);
        doThrow(abortFailure).when(producer).abortTransaction();

        RuntimeException thrown = assertThrows(RuntimeException.class,
                () -> new TicketEventProducer(producer, ticketStore,
                        mock(TicketEventOutcomeStore.class), spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event")
                        .produce(ticket, null));

        assertSame(insertFailure, thrown);
        assertSame(abortFailure, thrown.getSuppressed()[0]);
        verify(producer, never()).commitTransaction();
    }

    @Test
    @SuppressWarnings("unchecked")
    void replayPublishesNewEventLinkedToFailure() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketEventOutcomeStore outcomeStore = mock(TicketEventOutcomeStore.class);
        Connection connection = mock(Connection.class);
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, null);
        when(producer.getDBConnection()).thenReturn(connection);
        when(outcomeStore.lockFailedEvent(connection, original.getEventId())).thenReturn(Optional.of(original));

        TicketWorkEvent replay = new TicketEventProducer(producer, ticketStore, outcomeStore,
                spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event")
                .replay(original.getEventId());

        ArgumentCaptor<ProducerRecord<String, TicketWorkEvent>> sent = ArgumentCaptor.forClass(ProducerRecord.class);
        InOrder order = inOrder(producer, outcomeStore, ticketStore);
        order.verify(producer).beginTransaction();
        order.verify(outcomeStore).lockFailedEvent(connection, original.getEventId());
        order.verify(outcomeStore).markReplayed(connection, original.getEventId());
        order.verify(ticketStore).resetFailedForReplay(connection, 42L);
        order.verify(producer).send(sent.capture());
        order.verify(producer).commitTransaction();
        assertNotEquals(original.getEventId(), replay.getEventId());
        assertEquals(original.getEventId(), replay.getCausationId());
        assertEquals(42L, replay.getTicketId());
        assertEquals(replay, sent.getValue().value());
    }

    @Test
    @SuppressWarnings("unchecked")
    void metricFailureAfterReplayCommitDoesNotAbort() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketEventOutcomeStore outcomeStore = mock(TicketEventOutcomeStore.class);
        TicketTelemetry telemetry = spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create()));
        Connection connection = mock(Connection.class);
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, null);
        when(producer.getDBConnection()).thenReturn(connection);
        when(outcomeStore.lockFailedEvent(connection, original.getEventId())).thenReturn(Optional.of(original));
        doThrow(new IllegalStateException("metric exporter unavailable"))
                .when(telemetry).published("replayed");

        TicketWorkEvent replay = new TicketEventProducer(producer, ticketStore, outcomeStore,
                telemetry, "ticket_event").replay(original.getEventId());

        assertEquals(original.getEventId(), replay.getCausationId());
        verify(producer).commitTransaction();
        verify(producer, never()).abortTransaction();
    }

    @Test
    @SuppressWarnings("unchecked")
    void incompleteEventIsNotRepublished() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketEventOutcomeStore outcomeStore = mock(TicketEventOutcomeStore.class);
        Connection connection = mock(Connection.class);
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, null);
        original.setTicketId(null);
        UUID eventId = original.getEventId();
        when(producer.getDBConnection()).thenReturn(connection);
        when(outcomeStore.lockFailedEvent(connection, eventId)).thenReturn(Optional.of(original));

        assertThrows(IllegalStateException.class,
                () -> new TicketEventProducer(producer, ticketStore, outcomeStore,
                        spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event").replay(eventId));

        verify(producer).abortTransaction();
        verify(producer, never()).send(org.mockito.ArgumentMatchers.any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void missingFailureIsNotRepublished() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketEventOutcomeStore outcomeStore = mock(TicketEventOutcomeStore.class);
        Connection connection = mock(Connection.class);
        UUID eventId = UUID.randomUUID();
        when(producer.getDBConnection()).thenReturn(connection);
        when(outcomeStore.lockFailedEvent(connection, eventId)).thenReturn(Optional.empty());

        assertThrows(TicketEventProducer.FailedEventNotFoundException.class,
                () -> new TicketEventProducer(producer, ticketStore, outcomeStore,
                        spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event")
                        .replay(eventId));

        verify(producer).abortTransaction();
        verify(producer, never()).send(org.mockito.ArgumentMatchers.any());
        verify(producer, never()).commitTransaction();
    }

    @Test
    @SuppressWarnings("unchecked")
    void ticketNoLongerFailedIsNotRepublished() throws Exception {
        KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
        TicketStore ticketStore = mock(TicketStore.class);
        TicketEventOutcomeStore outcomeStore = mock(TicketEventOutcomeStore.class);
        Connection connection = mock(Connection.class);
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, null);
        when(producer.getDBConnection()).thenReturn(connection);
        when(outcomeStore.lockFailedEvent(connection, original.getEventId())).thenReturn(Optional.of(original));
        doThrow(new IllegalStateException("Failed ticket is no longer available for replay"))
                .when(ticketStore).resetFailedForReplay(connection, 42L);

        assertThrows(IllegalStateException.class,
                () -> new TicketEventProducer(producer, ticketStore, outcomeStore,
                        spy(new TicketTelemetry(new SimpleMeterRegistry(), ObservationRegistry.create())), "ticket_event")
                        .replay(original.getEventId()));

        verify(producer).abortTransaction();
        verify(producer, never()).send(org.mockito.ArgumentMatchers.any());
        verify(producer, never()).commitTransaction();
    }
}
