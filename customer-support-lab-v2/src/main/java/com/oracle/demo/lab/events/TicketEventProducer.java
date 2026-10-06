// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import java.sql.Connection;
import java.util.UUID;

import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketStore;
import com.oracle.demo.lab.ticket.TicketStatus;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("events")
public class TicketEventProducer {
    private static final Logger log = LoggerFactory.getLogger(TicketEventProducer.class);

    private final KafkaProducer<String, TicketWorkEvent> producer;
    private final TicketStore ticketStore;
    private final TicketEventOutcomeStore outcomeStore;
    private final TicketTelemetry telemetry;
    private final String topic;

    public TicketEventProducer(KafkaProducer<String, TicketWorkEvent> producer,
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

    public synchronized Long produce(SupportTicket ticket, UUID correlationId) {
        ticket.setWorkflowStatus(TicketStatus.RECEIVED);
        producer.beginTransaction();
        TicketWorkEvent event;
        try {
            ticket.setId(ticketStore.insert(producer.getDBConnection(), ticket));
            event = TicketWorkEvent.submitted(ticket.getId(), correlationId);
            EventTraceContext.inject(event);
            producer.send(event.toProducerRecord(topic));
            producer.commitTransaction();
        } catch (Exception e) {
            throw abortAfterFailure(e);
        }
        recordPublished("submitted");
        log.info("Created ticket id={} status={} eventId={} correlationId={}",
                ticket.getId(), ticket.getWorkflowStatus(), event.getEventId(), event.getCorrelationId());
        return ticket.getId();
    }

    public synchronized TicketWorkEvent replay(UUID failedEventId) {
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
            EventTraceContext.inject(replay);
            outcomeStore.markReplayed(connection, failedEventId);
            ticketStore.resetFailedForReplay(connection, replay.getTicketId());
            producer.send(replay.toProducerRecord(topic));
            producer.commitTransaction();
        } catch (Exception e) {
            throw abortAfterFailure(e);
        }
        recordPublished("replayed");
        log.info("Replayed ticket event originalEventId={} replayEventId={} ticketId={}",
                failedEventId, replay.getEventId(), replay.getTicketId());
        return replay;
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
