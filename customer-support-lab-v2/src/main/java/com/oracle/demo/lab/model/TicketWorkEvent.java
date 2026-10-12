// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.model;

import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.UUID;

/** A small, versioned event contract; ticket content remains in Oracle AI Database. */
public class TicketWorkEvent {
    public static final int CURRENT_SCHEMA_VERSION = 1;
    public static final String TICKET_SUBMITTED = "TICKET_SUBMITTED";

    private int schemaVersion;
    private Long ticketId;
    private String eventType;
    private UUID eventId;
    private UUID correlationId;
    private UUID causationId;
    private String createdAt;
    private String traceparent;
    private String tracestate;

    public TicketWorkEvent() {
    }

    public static TicketWorkEvent submitted(Long ticketId, UUID correlationId) {
        TicketWorkEvent event = new TicketWorkEvent();
        event.setSchemaVersion(CURRENT_SCHEMA_VERSION);
        event.setTicketId(ticketId);
        event.setEventType(TICKET_SUBMITTED);
        event.setEventId(UUID.randomUUID());
        event.setCorrelationId(correlationId == null ? UUID.randomUUID() : correlationId);
        event.setCreatedAt(java.time.Instant.now().toString());
        return event;
    }

    public TicketWorkEvent replayed(UUID replayEventId) {
        TicketWorkEvent replay = new TicketWorkEvent();
        replay.setSchemaVersion(schemaVersion);
        replay.setTicketId(ticketId);
        replay.setEventType(eventType);
        replay.setEventId(replayEventId);
        replay.setCorrelationId(correlationId);
        replay.setCausationId(eventId);
        replay.setCreatedAt(java.time.Instant.now().toString());
        return replay;
    }

    public boolean isReplayable() {
        return isSupportedEnvelope(schemaVersion, eventType, ticketId);
    }

    public static boolean isSupportedEnvelope(int schemaVersion, String eventType, Long ticketId) {
        return schemaVersion == CURRENT_SCHEMA_VERSION
                && TICKET_SUBMITTED.equals(eventType)
                && ticketId != null;
    }

    public ProducerRecord<String, TicketWorkEvent> toProducerRecord(String topic) {
        return new ProducerRecord<>(topic, ticketId.toString(), this);
    }

    public int getSchemaVersion() {
        return schemaVersion;
    }

    public void setSchemaVersion(int schemaVersion) {
        this.schemaVersion = schemaVersion;
    }

    public Long getTicketId() {
        return ticketId;
    }

    public void setTicketId(Long ticketId) {
        this.ticketId = ticketId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public UUID getEventId() {
        return eventId;
    }

    public void setEventId(UUID eventId) {
        this.eventId = eventId;
    }

    public UUID getCorrelationId() {
        return correlationId;
    }

    public void setCorrelationId(UUID correlationId) {
        this.correlationId = correlationId;
    }

    public UUID getCausationId() {
        return causationId;
    }

    public void setCausationId(UUID causationId) {
        this.causationId = causationId;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getTraceparent() {
        return traceparent;
    }

    public void setTraceparent(String traceparent) {
        this.traceparent = traceparent;
    }

    public String getTracestate() {
        return tracestate;
    }

    public void setTracestate(String tracestate) {
        this.tracestate = tracestate;
    }
}
