// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.model;

import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.spring.json.jsonb.JSONB;
import com.oracle.spring.json.kafka.OSONKafkaSerializationFactory;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serializer;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TicketWorkEventSerializationTest {
    @Test
    void osonRoundTripsTypedUuids() {
        OSONKafkaSerializationFactory factory = new OSONKafkaSerializationFactory(JSONB.createDefault());
        Serializer<TicketWorkEvent> serializer = factory.createSerializer();
        Deserializer<TicketWorkEvent> deserializer = factory.createDeserializer(TicketWorkEvent.class);
        UUID correlationId = UUID.randomUUID();
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, correlationId);
        TicketWorkEvent replay = original.replayed(UUID.randomUUID());
        replay.setTraceparent("00-0123456789abcdef0123456789abcdef-0123456789abcdef-01");

        TicketWorkEvent decoded = deserializer.deserialize("ticket_event",
                serializer.serialize("ticket_event", replay));

        assertEquals(replay.getEventId(), decoded.getEventId());
        assertEquals(correlationId, decoded.getCorrelationId());
        assertEquals(original.getEventId(), decoded.getCausationId());
        assertEquals(replay.getTraceparent(), decoded.getTraceparent());
    }

    @Test
    void replayRequiresSupportedCompleteEnvelope() {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        assertTrue(event.isReplayable());

        event.setTicketId(null);
        assertFalse(event.isReplayable());
        event.setTicketId(42L);
        event.setSchemaVersion(99);
        assertFalse(event.isReplayable());
    }
}
