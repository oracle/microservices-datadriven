// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketReadRouterTest {
    @Test
    void defaultsToCacheAndPreservesStaleMiss() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        SimpleMeterRegistry meters = new SimpleMeterRegistry();
        when(cache.findById(42L)).thenReturn(Optional.empty());
        TicketReadRouter router = new TicketReadRouter(primary, cache, meters);

        var result = router.byId(42L, null);

        assertEquals("true-cache", result.path());
        assertEquals(Optional.empty(), result.value());
        assertEquals(1.0, meters.get("support.ticket.reads")
                .tag("path", "true-cache").tag("outcome", "success").counter().count());
        verify(primary, never()).findById(42L);
    }

    @Test
    void fallsBackOnlyWhenCacheUnavailable() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        SimpleMeterRegistry meters = new SimpleMeterRegistry();
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        when(cache.getAllTickets()).thenThrow(new TrueCacheTicketReader.CacheUnavailableException(
                "unavailable", new SQLException("offline")));
        when(primary.getAllTickets()).thenReturn(List.of(ticket));
        TicketReadRouter router = new TicketReadRouter(primary, cache, meters);

        var result = router.all("cache");

        assertEquals("primary-fallback", result.path());
        assertEquals(List.of(ticket), result.value());
        assertEquals(1.0, meters.get("support.ticket.reads")
                .tag("path", "primary-fallback").tag("outcome", "success").counter().count());
    }

    @Test
    void explicitPrimaryBypassesCacheAndInvalidPathIsRejected() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        SimpleMeterRegistry meters = new SimpleMeterRegistry();
        TicketReadRouter router = new TicketReadRouter(primary, cache, meters);

        assertEquals("primary", router.all("primary").path());
        assertEquals(1.0, meters.get("support.ticket.reads")
                .tag("path", "primary").tag("outcome", "success").counter().count());
        verify(cache, never()).getAllTickets();
        assertThrows(TicketReadRouter.InvalidReadPathException.class,
                () -> router.all("unknown"));
    }

    @Test
    void cacheQueryErrorDoesNotHideBehindPrimaryFallback() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        when(cache.getAllTickets()).thenThrow(new IllegalStateException("bad cache query"));

        assertThrows(IllegalStateException.class, () -> router(primary, cache).all("cache"));
        verify(primary, never()).getAllTickets();
    }

    @Test
    void metricFailureDoesNotFailSuccessfulCacheRead() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        MeterRegistry meters = mock(MeterRegistry.class);
        when(cache.findById(42L)).thenReturn(Optional.empty());
        when(meters.counter("support.ticket.reads", "path", "true-cache", "outcome", "success"))
                .thenThrow(new IllegalStateException("metrics unavailable"));

        var result = new TicketReadRouter(primary, cache, meters).byId(42L, "cache");

        assertEquals("true-cache", result.path());
        assertEquals(Optional.empty(), result.value());
        verify(primary, never()).findById(42L);
    }

    @Test
    void metricFailureDoesNotMaskReadFailure() {
        TicketStore primary = mock(TicketStore.class);
        TrueCacheTicketReader cache = mock(TrueCacheTicketReader.class);
        MeterRegistry meters = mock(MeterRegistry.class);
        IllegalStateException readError = new IllegalStateException("bad cache query");
        when(cache.getAllTickets()).thenThrow(readError);
        when(meters.counter("support.ticket.reads", "path", "true-cache", "outcome", "failure"))
                .thenThrow(new IllegalStateException("metrics unavailable"));

        RuntimeException thrown = assertThrows(RuntimeException.class,
                () -> new TicketReadRouter(primary, cache, meters).all("cache"));

        assertSame(readError, thrown);
        verify(primary, never()).getAllTickets();
    }

    private static TicketReadRouter router(TicketStore primary, TrueCacheTicketReader cache) {
        return new TicketReadRouter(primary, cache, new SimpleMeterRegistry());
    }
}
