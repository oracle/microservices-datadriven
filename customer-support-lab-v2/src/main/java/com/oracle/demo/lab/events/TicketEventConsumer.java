// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.bmc.model.BmcException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.time.Duration;
import java.util.Collections;
import java.util.UUID;

import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketStore;
import com.oracle.demo.lab.ticket.TicketStatus;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import io.micrometer.observation.Observation;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.web.client.RestClientResponseException;

@Component
@Profile("events")
public class TicketEventConsumer implements Runnable {
    private static final Logger log = LoggerFactory.getLogger(TicketEventConsumer.class);
    private final KafkaConsumer<String, TicketWorkEvent> consumer;
    private final TicketEventProcessor eventProcessor;
    private final TicketStore ticketStore;
    private final TicketEventOutcomeStore outcomeStore;
    private final TicketTelemetry telemetry;
    private final ObjectProvider<DemoFailureInjector> demoFailureInjector;
    private final String topic;
    private final int maxAttempts;
    private final long initialBackoffMillis;
    private volatile boolean running = true;

    public TicketEventConsumer(KafkaConsumer<String, TicketWorkEvent> consumer,
                               TicketEventProcessor eventProcessor,
                               TicketStore ticketStore,
                               TicketEventOutcomeStore outcomeStore,
                               TicketTelemetry telemetry,
                               ObjectProvider<DemoFailureInjector> demoFailureInjector,
                               @Value("${okafka.topic.tickets}") String topic,
                               @Value("${app.events.retry.max-attempts:3}") int maxAttempts,
                               @Value("${app.events.retry.backoff-ms:250}") long initialBackoffMillis) {
        this.consumer = consumer;
        this.eventProcessor = eventProcessor;
        this.ticketStore = ticketStore;
        this.outcomeStore = outcomeStore;
        this.telemetry = telemetry;
        this.demoFailureInjector = demoFailureInjector;
        this.topic = topic;
        this.maxAttempts = Math.max(1, maxAttempts);
        this.initialBackoffMillis = Math.max(0, initialBackoffMillis);
    }

    @Override
    public void run() {
        try {
            consumer.subscribe(Collections.singletonList(topic));
            log.info("Subscribed to topic {}", topic);
            while (running && !Thread.currentThread().isInterrupted()) {
                Connection connection = null;
                try {
                    ConsumerRecords<String, TicketWorkEvent> records = consumer.poll(Duration.ofMillis(2000));
                    for (ConsumerRecord<String, TicketWorkEvent> record : records) {
                        connection = consumer.getDBConnection();
                        consumeAndCommit(connection, record);
                    }
                } catch (InterruptedException e) {
                    rollback(connection);
                    Thread.currentThread().interrupt();
                } catch (Exception e) {
                    rollback(connection);
                    log.error("Ticket event transaction failed; the message will be redelivered ({})",
                            e.getClass().getSimpleName());
                }
            }
        } finally {
            consumer.close();
        }
    }

    public void stop() {
        running = false;
    }

    void consumeAndCommit(Connection connection, ConsumerRecord<String, TicketWorkEvent> record)
            throws Exception {
        TicketWorkEvent event = record.value();
        long started = System.nanoTime();
        try (io.opentelemetry.context.Scope traceScope = event == null ?
                io.opentelemetry.context.Context.root().makeCurrent() :
                EventTraceContext.extract(event).makeCurrent();
             MDC.MDCCloseable eventId = MDC.putCloseable("eventId", event == null ? null : String.valueOf(event.getEventId()));
             MDC.MDCCloseable correlationId = MDC.putCloseable("correlationId", event == null ? null : String.valueOf(event.getCorrelationId()));
             MDC.MDCCloseable ticketId = MDC.putCloseable("ticketId", event == null ? null : String.valueOf(event.getTicketId()))) {
            Observation observation = telemetry.eventObservation().start();
            String outcome = null;
            boolean committed = false;
            try (Observation.Scope scope = observation.openScope()) {
                outcome = processRecord(connection, record);
                // Count the outcome only after the TxEventQ acknowledgement commits.
                consumer.commitSync();
                committed = true;
                telemetry.completed(outcome, event, System.nanoTime() - started);
            } catch (Exception error) {
                if (!committed) {
                    observation.error(error);
                    throw error;
                }
                log.warn("Post-commit ticket event telemetry failed ({})", error.getClass().getSimpleName());
            } finally {
                try {
                    observation.stop();
                } catch (RuntimeException error) {
                    log.warn("Could not stop ticket event observation ({})", error.getClass().getSimpleName());
                }
            }
            log.info("Committed ticket event topic={} partition={} offset={} outcome={}",
                    record.topic(), record.partition(), record.offset(), outcome);
        }
    }

    private static void rollback(Connection connection) {
        if (connection == null) {
            return;
        }
        try {
            connection.rollback();
        } catch (Exception rollbackError) {
            log.warn("Could not roll back failed ticket event transaction: {}",
                    rollbackError.getClass().getSimpleName());
        }
    }

    String processRecord(Connection connection, ConsumerRecord<String, TicketWorkEvent> record)
            throws Exception {
        TicketWorkEvent event = record.value();
        if (event == null) {
            event = new TicketWorkEvent();
        }
        boolean missingEventId = event.getEventId() == null;
        if (missingEventId) {
            String source = record.topic() + ":" + record.partition() + ":" + record.offset();
            event.setEventId(UUID.nameUUIDFromBytes(source.getBytes(StandardCharsets.UTF_8)));
        }

        if (outcomeStore.hasOutcome(connection, event.getEventId())) {
            log.info("Skipping ticket event with an existing outcome eventId={}", event.getEventId());
            return "duplicate";
        }

        Exception lastFailure = null;
        int attempts = 0;
        boolean ticketExists = false;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            attempts = attempt;
            Savepoint attemptStart = connection.setSavepoint();
            try {
                validate(event, missingEventId);
                SupportTicket ticket = ticketStore.findById(event.getTicketId())
                        .orElseThrow(() -> new NonRetryableTicketEventException("Ticket not found"));
                ticketExists = true;
                DemoFailureInjector demoFailure = demoFailureInjector.getIfAvailable();
                if (demoFailure != null) {
                    demoFailure.failForDemo(event, ticket, attempt, maxAttempts);
                }
                ticket.setWorkflowStatus(TicketStatus.TRIAGED);
                ticketStore.updateWorkflowStatus(connection, ticket.getId(), ticket.getWorkflowStatus());
                eventProcessor.processRecord(connection, event, ticket);
                outcomeStore.markProcessed(connection, event);
                return "processed";
            } catch (Exception e) {
                lastFailure = e;
                connection.rollback(attemptStart);
                boolean retryable = isRetryable(e);
                if (!retryable || attempt == maxAttempts) {
                    break;
                }
                long delay = initialBackoffMillis * (1L << Math.min(attempt - 1, 10));
                log.warn("Retrying ticket event eventId={} attempt={} of {} after {}ms ({})",
                        event.getEventId(), attempt, maxAttempts, delay, e.getClass().getSimpleName());
                telemetry.retried();
                if (delay > 0) {
                    Thread.sleep(delay);
                }
            }
        }

        // Each failed attempt was rolled back before recording the durable failure outcome.
        if (!ticketExists && event.getTicketId() != null) {
            ticketExists = ticketStore.findById(event.getTicketId()).isPresent();
        }
        if (ticketExists) {
            ticketStore.updateWorkflowStatus(connection, event.getTicketId(), TicketStatus.FAILED);
        }
        String failureType = lastFailure.getClass().getSimpleName();
        outcomeStore.recordFailure(connection, event, attempts, failureType);
        log.warn("Ticket event recorded as failed eventId={} ticketId={} attempts={} failureType={}",
                event.getEventId(), event.getTicketId(), attempts, failureType);
        return "failed";
    }

    private static void validate(TicketWorkEvent event, boolean missingEventId) {
        if (missingEventId) {
            throw new NonRetryableTicketEventException("Missing event UUID");
        }
        if (event.getSchemaVersion() != TicketWorkEvent.CURRENT_SCHEMA_VERSION) {
            throw new NonRetryableTicketEventException("Unsupported ticket event schema version");
        }
        if (!TicketWorkEvent.TICKET_SUBMITTED.equals(event.getEventType())
                || event.getTicketId() == null) {
            throw new NonRetryableTicketEventException("Invalid ticket work event");
        }
    }

    static boolean isRetryable(Throwable failure) {
        if (failure instanceof NonRetryableTicketEventException || failure instanceof IllegalArgumentException) {
            return false;
        }
        for (Throwable cause = failure; cause != null; cause = cause.getCause()) {
            if (cause instanceof TransientDataAccessException
                    || cause instanceof java.sql.SQLTransientException
                    || cause instanceof java.sql.SQLRecoverableException
                    || cause instanceof IOException) {
                return true;
            }
            if (cause instanceof SQLException sqlException) {
                String state = sqlException.getSQLState();
                if (state != null && (state.startsWith("08") || state.startsWith("40")
                        || state.startsWith("53") || state.startsWith("57"))) {
                    return true;
                }
            }
            if (cause instanceof RestClientResponseException responseException) {
                int status = responseException.getStatusCode().value();
                if (status == 429 || status >= 500) {
                    return true;
                }
            }
            if (cause instanceof BmcException bmcException) {
                int status = bmcException.getStatusCode();
                if (bmcException.isTimeout() || status == 429 || status >= 500) {
                    return true;
                }
            }
        }
        return false;
    }

    private static final class NonRetryableTicketEventException extends RuntimeException {
        private NonRetryableTicketEventException(String message) {
            super(message);
        }
    }
}
