// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.TraceFlags;
import io.opentelemetry.api.trace.TraceState;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class EventTraceContextTest {
    @Test
    void propagatesParentSpanAcrossEventEnvelope() {
        SpanContext parent = SpanContext.create(
                "0123456789abcdef0123456789abcdef", "0123456789abcdef",
                TraceFlags.getSampled(), TraceState.getDefault());
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        try (Scope ignored = Context.root().with(Span.wrap(parent)).makeCurrent()) {
            EventTraceContext.inject(event);
        }

        assertEquals(parent.getTraceId(), Span.fromContext(EventTraceContext.extract(event))
                .getSpanContext().getTraceId());
        assertEquals(parent.getSpanId(), Span.fromContext(EventTraceContext.extract(event))
                .getSpanContext().getSpanId());
    }
}
