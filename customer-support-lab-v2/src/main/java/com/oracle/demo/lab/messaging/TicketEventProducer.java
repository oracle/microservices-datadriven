// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;
import com.oracle.demo.lab.persistence.TicketStore;

import java.sql.Connection;
import java.util.UUID;

import org.oracle.okafka.clients.producer.KafkaProducer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class TicketEventProducer {
    private static final Logger log = LoggerFactory.getLogger(TicketEventProducer.class);

    private final KafkaProducer<String, TicketWorkEvent> producer;
    private final TicketStore ticketStore;
    private final TicketEventOutcomeStore outcomeStore;
    private final TicketTelemetry telemetry;
    private final String topic;

    public TicketEventProducer(@Qualifier("ticketProducer") KafkaProducer<String, TicketWorkEvent> producer,
                               TicketStore ticketStore,
                               TicketEventOutcomeStore outcomeStore,
                               TicketTelemetry telemetry,
                               @Value("${okafka.topic.tickets}") String topic) {
        this.producer = producer;
        this.ticketStore = ticketStore;
        this.outcomeStore = outcomeStore;
        this.telemetry = telemetry;
        this.topic = topic;
    }

    public Long produce(SupportTicket ticket, UUID correlationId) {
        return telemetry.operation("support.ticket.submit", () -> submit(ticket, correlationId));
    }

    private Long submit(SupportTicket ticket, UUID correlationId) {
        synchronized (producer) {
            ticket.setWorkflowStatus(TicketStatus.RECEIVED);
            producer.beginTransaction();
            TicketWorkEvent event;
            try {
                ticket.setId(ticketStore.insert(producer.getDBConnection(), ticket));
                event = TicketWorkEvent.submitted(ticket.getId(), correlationId);
                var record = event.toProducerRecord(topic);
                telemetry.publish(record, () -> {
                    producer.send(record);
                    producer.commitTransaction();
                });
            } catch (Exception e) {
                throw abortAfterFailure(e);
            }
            recordPublished("submitted");
            log.info("Created ticket id={} status={} eventId={} correlationId={}",
                    ticket.getId(), ticket.getWorkflowStatus(), event.getEventId(), event.getCorrelationId());
            return ticket.getId();
        }
    }

    public TicketWorkEvent replay(UUID failedEventId) {
        return telemetry.operation("support.ticket.replay", () -> replayFailedEvent(failedEventId));
    }

    private TicketWorkEvent replayFailedEvent(UUID failedEventId) {
        synchronized (producer) {
            producer.beginTransaction();
            TicketWorkEvent replay;
            try {
                Connection connection = producer.getDBConnection();
                TicketWorkEvent original = outcomeStore.lockFailedEvent(connection, failedEventId)
                        .orElseThrow(() -> new FailedEventNotFoundException(failedEventId));
                if (!original.isReplayable()) {
                    throw new IllegalStateException("Failed event has an unsupported or incomplete envelope");
                }
                replay = original.replayed(UUID.randomUUID());
                outcomeStore.markReplayed(connection, failedEventId);
                ticketStore.resetFailedForReplay(connection, replay.getTicketId());
                var record = replay.toProducerRecord(topic);
                telemetry.publish(record, () -> {
                    producer.send(record);
                    producer.commitTransaction();
                });
            } catch (Exception e) {
                throw abortAfterFailure(e);
            }
            recordPublished("replayed");
            log.info("Replayed ticket event originalEventId={} replayEventId={} ticketId={}",
                    failedEventId, replay.getEventId(), replay.getTicketId());
            return replay;
        }
    }

    private RuntimeException abortAfterFailure(Exception failure) {
        try {
            producer.abortTransaction();
        } catch (RuntimeException abortFailure) {
            failure.addSuppressed(abortFailure);
        }
        return failure instanceof RuntimeException runtimeException
                ? runtimeException : new RuntimeException(failure);
    }

    private void recordPublished(String kind) {
        try {
            telemetry.published(kind);
        } catch (RuntimeException e) {
            log.warn("Could not record ticket publication metric kind={}", kind, e);
        }
    }

    public static final class FailedEventNotFoundException extends RuntimeException {
        public FailedEventNotFoundException(UUID eventId) {
            super("No failed ticket event found: " + eventId);
        }
    }
}
