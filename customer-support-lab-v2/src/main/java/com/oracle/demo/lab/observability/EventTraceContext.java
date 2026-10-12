// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import com.oracle.demo.lab.model.TicketWorkEvent;

import io.opentelemetry.context.Context;
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapSetter;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;

/** Propagates only W3C trace context, never ticket content, through TxEventQ. */
public final class EventTraceContext {
    private static final W3CTraceContextPropagator PROPAGATOR = W3CTraceContextPropagator.getInstance();
    private static final TextMapSetter<TicketWorkEvent> SETTER = (event, key, value) -> {
        if ("traceparent".equals(key)) {
            event.setTraceparent(value);
        } else if ("tracestate".equals(key)) {
            event.setTracestate(value);
        }
    };
    private static final TextMapGetter<TicketWorkEvent> GETTER = new TextMapGetter<>() {
        @Override
        public Iterable<String> keys(TicketWorkEvent event) {
            return java.util.List.of("traceparent", "tracestate");
        }

        @Override
        public String get(TicketWorkEvent event, String key) {
            return switch (key) {
                case "traceparent" -> event.getTraceparent();
                case "tracestate" -> event.getTracestate();
                default -> null;
            };
        }
    };

    private EventTraceContext() {
    }

    public static void inject(TicketWorkEvent event) {
        PROPAGATOR.inject(Context.current(), event, SETTER);
    }

    public static Context extract(TicketWorkEvent event) {
        return PROPAGATOR.extract(Context.root(), event, GETTER);
    }
}
