// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.EventTraceContext;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import com.oracle.demo.lab.persistence.TicketStore;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.SQLException;

/** Commits the review, ticket feedback, and regeneration request together. */
@Component
@Profile("events & ai & blockchain")
public class TicketReviewService {
    private static final Logger log = LoggerFactory.getLogger(TicketReviewService.class);
    private final KafkaProducer<String, TicketWorkEvent> producer;
    private final TicketApprovalStore approvals;
    private final TicketStore tickets;
    private final TicketTelemetry telemetry;
    private final String topic;

    public TicketReviewService(@Qualifier("reviewProducer") KafkaProducer<String, TicketWorkEvent> producer,
                               TicketApprovalStore approvals, TicketStore tickets, TicketTelemetry telemetry,
                               @Value("${okafka.topic.tickets}") String topic) {
        this.producer = producer;
        this.approvals = approvals;
        this.tickets = tickets;
        this.telemetry = telemetry;
        this.topic = topic;
    }

    public TicketApproval record(long ticketId, TicketApproval.Request request) {
        request.validate();
        TicketApprovalStore.RecordedReview recorded;
        boolean feedbackPublished = false;
        // Serialize feedback requests on their own producer; ticket submission uses a separate instance.
        synchronized (producer) {
            producer.beginTransaction();
            try {
                Connection connection = producer.getDBConnection();
                recorded = approvals.record(connection, ticketId, request);
                if (recorded.created() && request.decision() == TicketApproval.Decision.REJECTED) {
                    tickets.addReviewFeedback(connection, ticketId, request.reason());
                    TicketWorkEvent event = TicketWorkEvent.feedbackSubmitted(ticketId, request.actionId());
                    EventTraceContext.inject(event);
                    producer.send(event.toProducerRecord(topic));
                    feedbackPublished = true;
                }
                producer.commitTransaction();
            } catch (Exception failure) {
                try {
                    producer.abortTransaction();
                } catch (RuntimeException abortFailure) {
                    failure.addSuppressed(abortFailure);
                }
                if (failure instanceof SQLException sql && sql.getErrorCode() == 1) {
                    throw new TicketApprovalStore.ApprovalConflictException(
                            "actionId already belongs to another review");
                }
                throw failure instanceof RuntimeException runtime ? runtime
                        : new IllegalStateException("Could not record ticket review", failure);
            }
        }
        if (feedbackPublished) {
            try {
                telemetry.published("feedback");
            } catch (RuntimeException failure) {
                log.warn("Could not record committed feedback publication metric ({})",
                        failure.getClass().getSimpleName());
            }
        }
        return recorded.approval();
    }
}
