// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import com.oracle.demo.lab.model.TicketWorkEvent;
import io.micrometer.observation.transport.ReceiverContext;
import io.micrometer.observation.transport.SenderContext;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.nio.charset.StandardCharsets;

/** Micrometer transport contexts for TxEventQ, with envelope compatibility. */
public final class EventTraceContext {
    private EventTraceContext() {
    }

    public static SenderContext<ProducerRecord<String, TicketWorkEvent>> sender(
            ProducerRecord<String, TicketWorkEvent> record) {
        var context = new SenderContext<ProducerRecord<String, TicketWorkEvent>>((carrier, key, value) -> {
            carrier.headers().remove(key).add(key, value.getBytes(StandardCharsets.UTF_8));
            // Preserve the existing OSON envelope contract as well as Kafka headers.
            if ("traceparent".equals(key)) {
                carrier.value().setTraceparent(value);
            } else if ("tracestate".equals(key)) {
                carrier.value().setTracestate(value);
            }
        });
        context.setCarrier(record);
        return context;
    }

    public static ReceiverContext<ConsumerRecord<String, TicketWorkEvent>> receiver(
            ConsumerRecord<String, TicketWorkEvent> record) {
        var context = new ReceiverContext<ConsumerRecord<String, TicketWorkEvent>>((carrier, key) -> {
            var header = carrier.headers().lastHeader(key);
            if (header != null && header.value() != null) {
                return new String(header.value(), StandardCharsets.UTF_8);
            }
            // Messages queued before transport observations carried context in the payload.
            TicketWorkEvent event = carrier.value();
            if (event == null) {
                return null;
            }
            return switch (key) {
                case "traceparent" -> event.getTraceparent();
                case "tracestate" -> event.getTracestate();
                default -> null;
            };
        });
        context.setCarrier(record);
        return context;
    }
}
