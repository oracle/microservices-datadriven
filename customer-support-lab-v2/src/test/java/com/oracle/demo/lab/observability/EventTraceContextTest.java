// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import com.oracle.demo.lab.model.TicketWorkEvent;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

class EventTraceContextTest {
    private static final String PARENT = "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01";

    @Test
    void senderReplacesHeadersAndMirrorsW3cContextIntoTheEnvelope() {
        var event = TicketWorkEvent.submitted(42L, null);
        var record = event.toProducerRecord("ticket_event");
        record.headers().add("traceparent", "old".getBytes(StandardCharsets.UTF_8));
        var sender = EventTraceContext.sender(record);

        sender.getSetter().set(record, "traceparent", PARENT);
        sender.getSetter().set(record, "tracestate", "vendor=value");

        assertEquals(PARENT, event.getTraceparent());
        assertEquals("vendor=value", event.getTracestate());
        assertEquals(1, java.util.stream.StreamSupport.stream(
                record.headers().headers("traceparent").spliterator(), false).count());
        assertEquals(PARENT, new String(record.headers().lastHeader("traceparent").value(), StandardCharsets.UTF_8));
    }

    @Test
    void receiverPrefersHeadersAndFallsBackToLegacyEnvelopeContext() {
        var event = TicketWorkEvent.submitted(42L, null);
        event.setTraceparent(PARENT);
        var record = new ConsumerRecord<>("ticket_event", 0, 0, "42", event);
        var receiver = EventTraceContext.receiver(record);

        assertEquals(PARENT, receiver.getGetter().get(record, "traceparent"));
        record.headers().add("traceparent", "header-parent".getBytes(StandardCharsets.UTF_8));
        assertEquals("header-parent", receiver.getGetter().get(record, "traceparent"));
        assertNull(receiver.getGetter().get(record, "baggage"));
    }

    @Test
    void nullPayloadHasNoFallbackContext() {
        var record = new ConsumerRecord<String, TicketWorkEvent>("ticket_event", 0, 0, "42", null);
        assertNull(EventTraceContext.receiver(record).getGetter().get(record, "traceparent"));
    }
}
