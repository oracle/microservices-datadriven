// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.processing;

import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketWorkEvent;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;

class LogEventProcessorTest {
    @Test
    void feedbackCannotBeAcknowledgedAsOrdinaryTriageWithoutAi() {
        assertThrows(IllegalArgumentException.class, () -> new LogEventProcessor().processRecord(null,
                TicketWorkEvent.feedbackSubmitted(42L, UUID.randomUUID()), new SupportTicket()));
    }
}
