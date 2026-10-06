// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotEquals;

class SupportTicketIdentityTest {
    @Test
    void distinctUnsavedTicketsDoNotCompareEqual() {
        assertNotEquals(new SupportTicket(), new SupportTicket());
    }
}
