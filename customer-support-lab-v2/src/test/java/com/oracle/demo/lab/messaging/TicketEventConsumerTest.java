// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.messaging.TicketEventConsumer;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.processing.DemoFailureInjector;
import com.oracle.demo.lab.processing.TicketEventProcessor;
import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;
import com.oracle.demo.lab.persistence.TicketStore;

import com.oracle.bmc.model.BmcException;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.junit.jupiter.api.Test;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import io.micrometer.observation.Observation;
import io.micrometer.observation.ObservationRegistry;
import org.springframework.beans.factory.ObjectProvider;

import java.sql.Connection;
import java.sql.Savepoint;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

import org.springframework.dao.TransientDataAccessResourceException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class TicketEventConsumerTest {
    private final KafkaConsumer<String, TicketWorkEvent> kafka = mock(KafkaConsumer.class);
    private final TicketEventProcessor processor = mock(TicketEventProcessor.class);
    private final TicketStore tickets = mock(TicketStore.class);
    private final TicketEventOutcomeStore outcomes = mock(TicketEventOutcomeStore.class);
    private final TicketTelemetry telemetry = mock(TicketTelemetry.class);
    private final ObjectProvider<DemoFailureInjector> demoFailure = mock(ObjectProvider.class);
    private final Connection connection = mock(Connection.class);

    @Test
    void eventWithCommittedOutcomeDoesNotWriteTicketOrProcessAgain() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        when(outcomes.hasOutcome(connection, event.getEventId())).thenReturn(true);

        assertEquals("duplicate", consumer().processRecord(connection, record(event)));

        verifyNoInteractions(tickets, processor);
        verify(outcomes, never()).markProcessed(any(), any());
        verify(outcomes, never()).recordFailure(any(), any(), anyInt(), any());
    }

    @Test
    void processedEventRecordsIdempotencyAfterTicketWork() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        when(connection.setSavepoint()).thenReturn(mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));

        assertEquals("processed", consumer().processRecord(connection, record(event)));

        var order = inOrder(tickets, processor, outcomes);
        order.verify(tickets).updateWorkflowStatus(connection, 42L, TicketStatus.TRIAGED);
        order.verify(processor).processRecord(connection, event, ticket);
        order.verify(outcomes).markProcessed(connection, event);
        verify(outcomes, never()).recordFailure(any(), any(), anyInt(), any());
    }

    @Test
    void feedbackEventUsesTheSameProcessingAndOutcomeTransaction() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.feedbackSubmitted(42L, UUID.randomUUID());
        SupportTicket ticket = ticket("Lost MFA authenticator");
        ticket.setReviewFeedback("Use the test tenant.");
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));

        assertEquals("processed", consumer().processRecord(connection, record(event)));

        verify(processor).processRecord(connection, event, ticket);
        verify(outcomes).markProcessed(connection, event);
        verify(outcomes, never()).recordFailure(any(), any(), anyInt(), any());
    }

    @Test
    void acknowledgesOnlyAfterIdempotencyWrite() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        when(connection.setSavepoint()).thenReturn(mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(telemetry.eventObservation()).thenReturn(
                Observation.createNotStarted("support.ticket.consume", ObservationRegistry.create()));

        consumer().consumeAndCommit(connection, record(event));

        var order = inOrder(outcomes, kafka);
        order.verify(outcomes).markProcessed(connection, event);
        order.verify(kafka).commitSync();
        verify(telemetry).completed(eq("processed"), eq(event), anyLong());
    }

    @Test
    void telemetryFailureAfterAcknowledgementDoesNotFailCommittedEvent() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        when(connection.setSavepoint()).thenReturn(mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(telemetry.eventObservation()).thenReturn(
                Observation.createNotStarted("support.ticket.consume", ObservationRegistry.create()));
        doThrow(new IllegalStateException("metric exporter unavailable"))
                .when(telemetry).completed(eq("processed"), eq(event), anyLong());

        assertDoesNotThrow(() -> consumer().consumeAndCommit(connection, record(event)));

        verify(kafka).commitSync();
        verify(connection, never()).rollback();
    }

    @Test
    void acknowledgementFailureStillFailsEvent() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        when(connection.setSavepoint()).thenReturn(mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(telemetry.eventObservation()).thenReturn(
                Observation.createNotStarted("support.ticket.consume", ObservationRegistry.create()));
        doThrow(new IllegalStateException("commit failed")).when(kafka).commitSync();

        assertThrows(IllegalStateException.class,
                () -> consumer().consumeAndCommit(connection, record(event)));

        verify(telemetry, never()).completed(any(), any(), anyLong());
    }

    @Test
    void shutdownStopsPollerAndClosesConsumerOnItsThread() {
        TicketEventConsumer consumer = consumer();
        when(kafka.poll(any(Duration.class))).thenAnswer(invocation -> {
            consumer.stop();
            return ConsumerRecords.empty();
        });

        consumer.run();

        verify(kafka).poll(any(Duration.class));
        verify(kafka).close();
    }

    @Test
    void demoFailureRollsBackWorkAndRecordsReplayableFailure() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("[demo-fail-once] Lost MFA authenticator");
        Savepoint attemptStart = mock(Savepoint.class);
        when(connection.setSavepoint()).thenReturn(attemptStart);
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(demoFailure.getIfAvailable()).thenReturn(new DemoFailureInjector());

        assertEquals("failed", consumer().processRecord(connection, record(event)));

        var order = inOrder(connection, tickets, outcomes);
        order.verify(connection).rollback(attemptStart);
        order.verify(tickets).updateWorkflowStatus(connection, 42L, TicketStatus.FAILED);
        order.verify(outcomes).recordFailure(eq(connection), eq(event), eq(1), eq("DemoFailureException"));
        verifyNoInteractions(processor);
        verify(outcomes, never()).markProcessed(any(), any());
    }

    @Test
    void replayedDemoEventRetriesOnceThenCompletes() throws Exception {
        TicketWorkEvent replay = TicketWorkEvent.submitted(42L, null).replayed(UUID.randomUUID());
        SupportTicket ticket = ticket("[demo-fail-once] Lost MFA authenticator");
        when(connection.setSavepoint()).thenAnswer(invocation -> mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(demoFailure.getIfAvailable()).thenReturn(new DemoFailureInjector());

        assertEquals("processed", consumer().processRecord(connection, record(replay)));

        verify(connection).rollback(any(Savepoint.class));
        verify(telemetry).retried();
        verify(processor).processRecord(connection, replay, ticket);
        verify(outcomes).markProcessed(connection, replay);
        verify(outcomes, never()).recordFailure(any(), any(), anyInt(), any());
    }

    @Test
    void replayedDemoEventSkipsTransientInjectionWhenRetriesDisabled() throws Exception {
        TicketWorkEvent replay = TicketWorkEvent.submitted(42L, null).replayed(UUID.randomUUID());
        SupportTicket ticket = ticket("[demo-fail-once] Lost MFA authenticator");
        when(connection.setSavepoint()).thenReturn(mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        when(demoFailure.getIfAvailable()).thenReturn(new DemoFailureInjector());

        assertEquals("processed", consumer(1).processRecord(connection, record(replay)));

        verify(connection, never()).rollback(any(Savepoint.class));
        verify(telemetry, never()).retried();
        verify(outcomes).markProcessed(connection, replay);
    }

    @Test
    void exhaustedTransientFailureRecordsOneReplayableOutcome() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        when(connection.setSavepoint()).thenAnswer(invocation -> mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        doThrow(new TransientDataAccessResourceException("Temporary database failure"))
                .when(processor).processRecord(connection, event, ticket);

        assertEquals("failed", consumer().processRecord(connection, record(event)));

        verify(processor, times(3)).processRecord(connection, event, ticket);
        verify(telemetry, times(2)).retried();
        verify(connection, times(3)).rollback(any(Savepoint.class));
        verify(outcomes).recordFailure(connection, event, 3, "TransientDataAccessResourceException");
        verify(outcomes, never()).markProcessed(any(), any());
    }

    @Test
    void exhaustedOciModelFailureRecordsReplayableOutcome() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        SupportTicket ticket = ticket("Lost MFA authenticator");
        BmcException modelError = mock(BmcException.class);
        when(modelError.getStatusCode()).thenReturn(429);
        when(connection.setSavepoint()).thenAnswer(invocation -> mock(Savepoint.class));
        when(tickets.findById(42L)).thenReturn(Optional.of(ticket));
        doThrow(modelError).when(processor).processRecord(connection, event, ticket);

        assertEquals("failed", consumer().processRecord(connection, record(event)));

        verify(processor, times(3)).processRecord(connection, event, ticket);
        verify(telemetry, times(2)).retried();
        verify(tickets).updateWorkflowStatus(connection, 42L, TicketStatus.FAILED);
        verify(outcomes).recordFailure(connection, event, 3, "BmcException");
        verify(outcomes, never()).markProcessed(any(), any());
    }

    private TicketEventConsumer consumer() {
        return consumer(3);
    }

    private TicketEventConsumer consumer(int maxAttempts) {
        return new TicketEventConsumer(kafka, processor, tickets, outcomes, telemetry,
                demoFailure, "ticket_event", maxAttempts, 0);
    }

    private static ConsumerRecord<String, TicketWorkEvent> record(TicketWorkEvent event) {
        return new ConsumerRecord<>("ticket_event", 0, 1L, "42", event);
    }

    private static SupportTicket ticket(String title) {
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        ticket.setTitle(title);
        return ticket;
    }
}
