// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ticket.SupportTicket;
import org.springframework.context.annotation.Profile;
import org.springframework.dao.TransientDataAccessResourceException;
import org.springframework.stereotype.Component;

/** Deterministic, opt-in failures that show both replay and bounded retry. */
@Component
@Profile("events & demo-failures")
public class DemoFailureInjector {
    public static final String TITLE_PREFIX = "[demo-fail-once]";

    public void failForDemo(TicketWorkEvent event, SupportTicket ticket, int attempt, int maxAttempts) {
        if (ticket.getTitle() == null || !ticket.getTitle().startsWith(TITLE_PREFIX)) {
            return;
        }
        if (event.getCausationId() == null) {
            throw new DemoFailureException();
        }
        if (attempt == 1 && maxAttempts > 1) {
            throw new DemoTransientFailureException();
        }
    }

    public static final class DemoFailureException extends IllegalArgumentException {
        private DemoFailureException() {
            super("Intentional demo failure; replay this event to finish processing");
        }
    }

    public static final class DemoTransientFailureException extends TransientDataAccessResourceException {
        private DemoTransientFailureException() {
            super("Intentional transient failure on the replayed event; the next attempt succeeds");
        }
    }
}
