// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ticket.SupportTicket;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class DemoFailureInjectorTest {
    private final DemoFailureInjector injector = new DemoFailureInjector();

    @Test
    void markedTicketFailsOriginalThenRetriesReplayOnce() {
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle(DemoFailureInjector.TITLE_PREFIX + " Login issue");
        TicketWorkEvent original = TicketWorkEvent.submitted(42L, null);
        TicketWorkEvent replay = original.replayed(UUID.randomUUID());

        assertThrows(DemoFailureInjector.DemoFailureException.class,
                () -> injector.failForDemo(original, ticket, 1, 3));
        assertThrows(DemoFailureInjector.DemoTransientFailureException.class,
                () -> injector.failForDemo(replay, ticket, 1, 3));
        assertDoesNotThrow(() -> injector.failForDemo(replay, ticket, 2, 3));
        assertDoesNotThrow(() -> injector.failForDemo(replay, ticket, 1, 1));
    }

    @Test
    void ordinaryTicketDoesNotFail() {
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Login issue");

        assertDoesNotThrow(() -> injector.failForDemo(TicketWorkEvent.submitted(42L, null), ticket, 1, 3));
    }
}
