// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import com.oracle.demo.lab.persistence.TicketStore;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.oracle.okafka.clients.producer.KafkaProducer;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class TicketReviewServiceTest {
    @SuppressWarnings("unchecked")
    private final KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
    private final TicketApprovalStore approvals = mock(TicketApprovalStore.class);
    private final TicketStore tickets = mock(TicketStore.class);
    private final TicketTelemetry telemetry = mock(TicketTelemetry.class);
    private final Connection connection = mock(Connection.class);
    private final TicketReviewService service = new TicketReviewService(producer, approvals, tickets, telemetry, "ticket_event");
    private final TicketApproval.Request rejection = new TicketApproval.Request(UUID.randomUUID(),
            TicketApproval.Decision.REJECTED, "reviewer", "The account is in the test tenant.");

    @Test
    @SuppressWarnings("unchecked")
    void rejectionCommitsReviewFeedbackAndEventOnTheSameProducerConnection() throws Exception {
        TicketApproval saved = prepare(rejection, true);

        assertEquals(saved, service.record(42, rejection));

        ArgumentCaptor<ProducerRecord<String, TicketWorkEvent>> sent = ArgumentCaptor.forClass(ProducerRecord.class);
        var calls = inOrder(producer, approvals, tickets);
        calls.verify(producer).beginTransaction();
        calls.verify(producer).getDBConnection();
        calls.verify(approvals).record(connection, 42, rejection);
        calls.verify(tickets).addReviewFeedback(connection, 42, rejection.reason());
        calls.verify(producer).send(sent.capture());
        calls.verify(producer).commitTransaction();
        TicketWorkEvent event = sent.getValue().value();
        assertEquals(TicketWorkEvent.TICKET_FEEDBACK_SUBMITTED, event.getEventType());
        assertEquals(rejection.actionId(), event.getCausationId());
        assertEquals(rejection.actionId(), event.getCorrelationId());
        assertEquals(42L, event.getTicketId());
        verify(telemetry).published("feedback");
    }

    @Test
    void duplicateRejectionDoesNotAppendFeedbackOrPublishAgain() throws Exception {
        prepare(rejection, false);

        service.record(42, rejection);

        verifyNoInteractions(tickets, telemetry);
        verify(producer, never()).send(any());
        verify(producer).commitTransaction();
    }

    @Test
    void approvalAcceptsSummaryWithoutRequestingRegeneration() throws Exception {
        var approved = new TicketApproval.Request(UUID.randomUUID(), TicketApproval.Decision.APPROVED, "reviewer", null);
        prepare(approved, true);

        service.record(42, approved);

        verifyNoInteractions(tickets, telemetry);
        verify(producer, never()).send(any());
        verify(producer).commitTransaction();
    }

    @Test
    void blankRejectionFeedbackNeverStartsATransaction() {
        var invalid = new TicketApproval.Request(UUID.randomUUID(), TicketApproval.Decision.REJECTED, "reviewer", " ");
        assertThrows(IllegalArgumentException.class, () -> service.record(42, invalid));
        verifyNoInteractions(producer, approvals, tickets);
    }

    @Test
    void publishFailureAbortsReviewAndFeedback() throws Exception {
        prepare(rejection, true);
        RuntimeException failure = new IllegalStateException("send failed");
        when(producer.send(any())).thenThrow(failure);

        assertSame(failure, assertThrows(IllegalStateException.class, () -> service.record(42, rejection)));

        verify(producer).abortTransaction();
        verify(producer, never()).commitTransaction();
        verifyNoInteractions(telemetry);
    }

    @Test
    void feedbackWriteFailureDoesNotPublish() throws Exception {
        prepare(rejection, true);
        doThrow(new SQLException("update failed")).when(tickets).addReviewFeedback(connection, 42, rejection.reason());

        assertThrows(IllegalStateException.class, () -> service.record(42, rejection));

        verify(producer).abortTransaction();
        verify(producer, never()).send(any());
        verify(producer, never()).commitTransaction();
    }

    @Test
    void commitFailureAbortsAndPreservesAbortFailure() throws Exception {
        prepare(rejection, true);
        var commitFailure = new IllegalStateException("commit failed");
        var abortFailure = new IllegalStateException("abort failed");
        doThrow(commitFailure).when(producer).commitTransaction();
        doThrow(abortFailure).when(producer).abortTransaction();

        assertSame(commitFailure, assertThrows(IllegalStateException.class, () -> service.record(42, rejection)));
        assertSame(abortFailure, commitFailure.getSuppressed()[0]);
        verifyNoInteractions(telemetry);
    }

    @Test
    void metricFailureDoesNotAbortCommittedReview() throws Exception {
        prepare(rejection, true);
        doThrow(new IllegalStateException("metrics unavailable")).when(telemetry).published("feedback");

        assertDoesNotThrow(() -> service.record(42, rejection));

        verify(producer).commitTransaction();
        verify(producer, never()).abortTransaction();
    }

    private TicketApproval prepare(TicketApproval.Request request, boolean created) throws Exception {
        when(producer.getDBConnection()).thenAnswer(invocation -> {
            assertTrue(Thread.holdsLock(producer), "feedback requests must serialize on their dedicated producer");
            return connection;
        });
        TicketApproval saved = new TicketApproval(request.actionId(), 42L, request.decision(), request.actorId(),
                request.reason(), "Old summary", "digest", "chat", "v1", Instant.now());
        when(approvals.record(connection, 42, request)).thenReturn(new TicketApprovalStore.RecordedReview(saved, created));
        return saved;
    }
}
