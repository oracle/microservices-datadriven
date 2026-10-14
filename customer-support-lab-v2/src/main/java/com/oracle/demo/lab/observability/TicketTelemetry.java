// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import com.oracle.demo.lab.model.TicketWorkEvent;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import io.micrometer.observation.Observation;
import io.micrometer.observation.ObservationRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.function.Supplier;

@Component
@Profile("events")
public class TicketTelemetry {
    private static final Logger log = LoggerFactory.getLogger(TicketTelemetry.class);

    private final MeterRegistry meters;
    private final ObservationRegistry observations;

    public TicketTelemetry(MeterRegistry meters, ObservationRegistry observations) {
        this.meters = meters;
        this.observations = observations;
        // Export a baseline before failures occur, for rolling-window counter queries.
        meters.counter("support.ticket.events", "outcome", "failed");
    }

    public Observation eventObservation() {
        return Observation.createNotStarted("support.ticket.consume", observations);
    }

    public void published(String kind) {
        meters.counter("support.ticket.published", "kind", kind).increment();
    }

    public void completed(String outcome, TicketWorkEvent event, long elapsedNanos) {
        meters.counter("support.ticket.events", "outcome", outcome).increment();
        Timer.builder("support.ticket.processing").tag("outcome", outcome)
                .register(meters).record(elapsedNanos, java.util.concurrent.TimeUnit.NANOSECONDS);
        if (event != null && event.getCreatedAt() != null) {
            try {
                Duration age = Duration.between(Instant.parse(event.getCreatedAt()), Instant.now());
                if (!age.isNegative()) {
                    Timer.builder("support.ticket.event.age").tag("outcome", outcome)
                            .register(meters).record(age);
                }
            } catch (java.time.format.DateTimeParseException ignored) {
                // Invalid event timestamps are handled by the workflow, not by telemetry.
            }
        }
    }

    public void retried() {
        recordMetric("retries", () -> meters.counter("support.ticket.retries").increment());
    }

    public <T> T step(String step, Supplier<T> work) {
        Observation observation = null;
        Observation.Scope scope = null;
        try {
            observation = Observation.createNotStarted("support.ticket.enrichment.step", observations)
                    .lowCardinalityKeyValue("step", step).start();
            scope = observation.openScope();
        } catch (RuntimeException error) {
            log.warn("Could not start ticket step observation step={} ({})", step,
                    error.getClass().getSimpleName());
        }
        try {
            T result;
            try {
                result = work.get();
            } catch (RuntimeException workError) {
                recordStepOutcome(observation, step, "failure", workError);
                throw workError;
            }
            recordStepOutcome(observation, step, "success", null);
            return result;
        } finally {
            if (scope != null) {
                Observation.Scope finalScope = scope;
                recordMetric("step scope", finalScope::close);
            }
            if (observation != null) {
                Observation finalObservation = observation;
                recordMetric("step observation", finalObservation::stop);
            }
        }
    }

    public void matches(String kind, int count) {
        recordMetric("matches", () -> io.micrometer.core.instrument.DistributionSummary
                .builder("support.ticket.matches").tag("kind", kind).register(meters).record(count));
    }

    private void recordStepOutcome(Observation observation, String step,
                                   String outcome, RuntimeException workError) {
        if (observation != null) {
            recordMetric("step observation", () -> {
                observation.lowCardinalityKeyValue("outcome", outcome);
                if (workError != null) {
                    observation.error(workError);
                }
            });
        }
        recordMetric("step", () -> meters.counter("support.ticket.step", "step", step,
                "outcome", outcome).increment());
    }

    private static void recordMetric(String signal, Runnable recording) {
        try {
            recording.run();
        } catch (RuntimeException error) {
            log.warn("Could not record ticket {} telemetry ({})", signal,
                    error.getClass().getSimpleName());
        }
    }
}
