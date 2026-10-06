// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import io.micrometer.observation.ObservationRegistry;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TicketTelemetryTest {
    @Test
    void recordsBoundedOutcomesAndStepFailures() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        TicketTelemetry telemetry = new TicketTelemetry(registry, ObservationRegistry.create());
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);

        telemetry.completed("processed", event, 1_000_000);
        telemetry.retried();
        assertThrows(IllegalStateException.class,
                () -> telemetry.step("summary", () -> { throw new IllegalStateException("temporary"); }));

        assertEquals(1, registry.get("support.ticket.events").tag("outcome", "processed")
                .counter().count());
        assertEquals(1, registry.get("support.ticket.retries").counter().count());
        assertEquals(1, registry.get("support.ticket.step").tag("step", "summary")
                .tag("outcome", "failure").counter().count());
    }

    @Test
    void successMetricFailureDoesNotTurnCompletedWorkIntoFailure() {
        MeterRegistry registry = mock(MeterRegistry.class);
        when(registry.counter("support.ticket.step", "step", "summary", "outcome", "success"))
                .thenThrow(new IllegalStateException("metrics unavailable"));
        TicketTelemetry telemetry = new TicketTelemetry(registry, ObservationRegistry.create());

        assertEquals("summary", telemetry.step("summary", () -> "summary"));
    }

    @Test
    void failureMetricFailureDoesNotMaskWorkFailure() {
        MeterRegistry registry = mock(MeterRegistry.class);
        when(registry.counter("support.ticket.step", "step", "summary", "outcome", "failure"))
                .thenThrow(new IllegalStateException("metrics unavailable"));
        TicketTelemetry telemetry = new TicketTelemetry(registry, ObservationRegistry.create());
        IllegalStateException workError = new IllegalStateException("model unavailable");

        RuntimeException thrown = assertThrows(RuntimeException.class,
                () -> telemetry.step("summary", () -> { throw workError; }));

        assertSame(workError, thrown);
    }

    @Test
    void retryAndMatchMetricFailuresDoNotInterruptWorkflow() {
        TicketTelemetry telemetry = new TicketTelemetry(mock(MeterRegistry.class),
                ObservationRegistry.create());

        assertDoesNotThrow(telemetry::retried);
        assertDoesNotThrow(() -> telemetry.matches("ticket", 2));
    }
}
