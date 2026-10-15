// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.persistence.TicketStore;
import com.oracle.demo.lab.processing.TicketEventProcessor;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import io.micrometer.observation.Observation;
import io.micrometer.observation.ObservationHandler;
import io.micrometer.observation.ObservationRegistry;
import io.micrometer.tracing.handler.DefaultTracingObservationHandler;
import io.micrometer.tracing.handler.PropagatingReceiverTracingObservationHandler;
import io.micrometer.tracing.handler.PropagatingSenderTracingObservationHandler;
import io.micrometer.tracing.otel.bridge.OtelCurrentTraceContext;
import io.micrometer.tracing.otel.bridge.OtelPropagator;
import io.micrometer.tracing.otel.bridge.OtelTracer;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.data.SpanData;
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor;
import io.opentelemetry.sdk.trace.export.SpanExporter;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.springframework.beans.factory.ObjectProvider;

import java.sql.Connection;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/** Exercises actual tracing handlers, not mocked observations or span IDs. */
@SuppressWarnings("unchecked")
class TicketTracingTest {
    private final List<SpanData> spans = new ArrayList<>();
    private final SdkTracerProvider provider = SdkTracerProvider.builder()
            .addSpanProcessor(SimpleSpanProcessor.create(new SpanExporter() {
                public CompletableResultCode export(Collection<SpanData> batch) {
                    spans.addAll(batch);
                    return CompletableResultCode.ofSuccess();
                }
                public CompletableResultCode flush() { return CompletableResultCode.ofSuccess(); }
                public CompletableResultCode shutdown() { return CompletableResultCode.ofSuccess(); }
            })).build();
    private final ObservationRegistry observations = ObservationRegistry.create();
    private final TicketTelemetry telemetry = new TicketTelemetry(new SimpleMeterRegistry(), observations);
    private final KafkaProducer<String, TicketWorkEvent> producer = mock(KafkaProducer.class);
    private final TicketStore tickets = mock(TicketStore.class);
    private final TicketEventOutcomeStore outcomes = mock(TicketEventOutcomeStore.class);
    private final TicketApprovalStore approvals = mock(TicketApprovalStore.class);
    private final Connection connection = mock(Connection.class);

    TicketTracingTest() throws Exception {
        var otel = provider.get("ticket-tracing-test");
        var tracer = new OtelTracer(otel, new OtelCurrentTraceContext(), event -> {});
        var propagator = new OtelPropagator(ContextPropagators.create(W3CTraceContextPropagator.getInstance()), otel);
        observations.observationConfig().observationHandler(new ObservationHandler.FirstMatchingCompositeObservationHandler(
                new PropagatingSenderTracingObservationHandler<>(tracer, propagator),
                new PropagatingReceiverTracingObservationHandler<>(tracer, propagator),
                new DefaultTracingObservationHandler(tracer)));
        when(producer.getDBConnection()).thenReturn(connection);
    }

    @AfterEach
    void closeTracing() { provider.close(); }

    @Test
    void submissionAndConsumerContinueTheHttpTraceThroughProducerHeaders() throws Exception {
        var ticket = new SupportTicket();
        when(tickets.insert(connection, ticket)).thenReturn(42L);
        http(() -> new TicketEventProducer(producer, tickets, outcomes, telemetry, "ticket_event").produce(ticket, null));
        consume(sent());

        assertParent("support.ticket.submit", "http post");
        assertParent("okafka.produce", "support.ticket.submit");
        assertParent("support.ticket.consume", "okafka.produce");
        assertEquals(SpanKind.PRODUCER, span("okafka.produce").getKind());
        assertEquals(SpanKind.CONSUMER, span("support.ticket.consume").getKind());
    }

    @Test
    void approvedReviewHasItsOwnSpanAndDoesNotPublish() throws Exception {
        prepareReview(TicketApproval.Decision.APPROVED);
        verify(producer, never()).send(any());
        assertParent("support.ticket.review", "http post");
        assertTrue(spans.stream().noneMatch(s -> s.getName().equals("okafka.produce")));
    }

    @Test
    void rejectedReviewLinksRegenerationBackToItsHttpTrace() throws Exception {
        prepareReview(TicketApproval.Decision.REJECTED);
        var record = sent();
        assertEquals(TicketWorkEvent.TICKET_FEEDBACK_SUBMITTED, record.value().getEventType());
        consume(record);
        assertParent("support.ticket.review", "http post");
        assertParent("okafka.produce", "support.ticket.review");
        assertParent("support.ticket.consume", "okafka.produce");
    }

    @Test
    void replayGetsANewProducerContextAndKeepsCausation() throws Exception {
        var original = TicketWorkEvent.submitted(42L, null);
        original.setTraceparent("00-0123456789abcdef0123456789abcdef-0123456789abcdef-01");
        when(outcomes.lockFailedEvent(connection, original.getEventId())).thenReturn(Optional.of(original));
        http(() -> new TicketEventProducer(producer, tickets, outcomes, telemetry, "ticket_event")
                .replay(original.getEventId()));
        var record = sent();
        consume(record);
        assertNotEquals(original.getTraceparent(), record.value().getTraceparent());
        assertEquals(original.getEventId(), record.value().getCausationId());
        assertParent("support.ticket.replay", "http post");
        assertParent("okafka.produce", "support.ticket.replay");
        assertParent("support.ticket.consume", "okafka.produce");
    }

    @Test
    void publishFailureRecordsErrorsAndStillAbortsTheTransaction() throws Exception {
        when(tickets.insert(any(), any())).thenReturn(42L);
        var failure = new IllegalStateException("send failed");
        when(producer.send(any())).thenThrow(failure);
        assertSame(failure, assertThrows(IllegalStateException.class, () -> http(() ->
                new TicketEventProducer(producer, tickets, outcomes, telemetry, "ticket_event")
                        .produce(new SupportTicket(), null))));
        assertEquals(StatusCode.ERROR, span("okafka.produce").getStatus().getStatusCode());
        assertEquals(StatusCode.ERROR, span("support.ticket.submit").getStatus().getStatusCode());
        verify(producer).abortTransaction();
        verify(producer, never()).commitTransaction();
    }

    private void prepareReview(TicketApproval.Decision decision) throws Exception {
        var request = new TicketApproval.Request(UUID.randomUUID(), decision, "reviewer", "Use the test tenant.");
        var saved = new TicketApproval(request.actionId(), 42L, decision, "reviewer", request.reason(),
                "Summary", "digest", "chat", "v1", Instant.now());
        when(approvals.record(connection, 42L, request)).thenReturn(new TicketApprovalStore.RecordedReview(saved, true));
        http(() -> new TicketReviewService(producer, approvals, tickets, telemetry, "ticket_event").record(42L, request));
    }

    private void consume(ProducerRecord<String, TicketWorkEvent> sent) throws Exception {
        var record = new ConsumerRecord<>(sent.topic(), 0, 0L, sent.key(), sent.value());
        sent.headers().forEach(record.headers()::add);
        // Close the HTTP/producer scopes before consuming on the worker, as in the app.
        when(outcomes.hasOutcome(connection, sent.value().getEventId())).thenReturn(true);
        new TicketEventConsumer(mock(KafkaConsumer.class), mock(TicketEventProcessor.class), tickets, outcomes,
                telemetry, mock(ObjectProvider.class), "ticket_event", 3, 0).consumeAndCommit(connection, record);
    }

    private ProducerRecord<String, TicketWorkEvent> sent() {
        ArgumentCaptor<ProducerRecord<String, TicketWorkEvent>> captor = ArgumentCaptor.forClass(ProducerRecord.class);
        verify(producer).send(captor.capture());
        return captor.getValue();
    }

    private void http(Runnable work) {
        Observation.createNotStarted("http.server.requests", observations).contextualName("http post").observe(work);
    }

    private SpanData span(String name) {
        return spans.stream().filter(s -> s.getName().equals(name)).findFirst().orElseThrow();
    }

    private void assertParent(String child, String parent) {
        assertEquals(span(parent).getTraceId(), span(child).getTraceId());
        assertEquals(span(parent).getSpanId(), span(child).getParentSpanId());
    }
}
