// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

/** Routes only freshness-tolerant ticket reads. Writes remain on TicketStore. */
@Component
public class TicketReadRouter {
    private static final Logger log = LoggerFactory.getLogger(TicketReadRouter.class);
    private final TicketStore primary;
    private final TrueCacheTicketReader cache;
    private final MeterRegistry meters;

    public TicketReadRouter(TicketStore primary, TrueCacheTicketReader cache, MeterRegistry meters) {
        this.primary = primary;
        this.cache = cache;
        this.meters = meters;
    }

    public ReadResult<List<SupportTicket>> all(String requestedPath) {
        return route(requestedPath, primary::getAllTickets, () -> cache.getAllTickets());
    }

    public ReadResult<Optional<SupportTicket>> byId(long id, String requestedPath) {
        return route(requestedPath, () -> primary.findById(id), () -> cache.findById(id));
    }

    private <T> ReadResult<T> route(String requestedPath, Supplier<T> primaryRead, Supplier<T> cacheRead) {
        boolean useCache = useCache(requestedPath);
        long started = System.nanoTime();
        String path = useCache ? "true-cache" : "primary";
        try {
            T value;
            if (!useCache) {
                value = primaryRead.get();
            } else {
                try {
                    value = cacheRead.get();
                } catch (TrueCacheTicketReader.CacheUnavailableException error) {
                    log.warn("True Cache unavailable; serving ticket read from primary ({})",
                            error.getCause().getClass().getSimpleName());
                    path = "primary-fallback";
                    value = primaryRead.get();
                }
            }
            record(path, "success", started);
            return new ReadResult<>(value, path);
        } catch (RuntimeException error) {
            record(path, "failure", started);
            throw error;
        }
    }

    private void record(String path, String outcome, long started) {
        try {
            meters.counter("support.ticket.reads", "path", path, "outcome", outcome).increment();
            Timer.builder("support.ticket.read.latency").tag("path", path).tag("outcome", outcome)
                    .register(meters).record(System.nanoTime() - started, TimeUnit.NANOSECONDS);
        } catch (RuntimeException error) {
            log.warn("Could not record ticket read metric path={} outcome={} ({})",
                    path, outcome, error.getClass().getSimpleName());
        }
    }

    public record ReadResult<T>(T value, String path) {
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public static final class InvalidReadPathException extends IllegalArgumentException {
        private InvalidReadPathException(String message) {
            super(message);
        }
    }

    private boolean useCache(String requested) {
        if (requested == null || requested.isBlank()) {
            return true;
        }
        return switch (requested.toLowerCase(java.util.Locale.ROOT)) {
            case "primary" -> false;
            case "cache" -> true;
            default -> throw new InvalidReadPathException("readPath must be primary or cache");
        };
    }
}
