// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SupportTicketJsonTest {
    @Test
    void ticketResponseContainsOnlyCoreFields() throws Exception {
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        ticket.setTitle("Lost MFA authenticator");
        ticket.setDescription("Cannot sign in");
        ticket.setWorkflowStatus(TicketStatus.ENRICHED);

        var json = new ObjectMapper().valueToTree(ticket);

        assertEquals(4, json.size());
        assertTrue(json.has("id"));
        assertEquals("ENRICHED", json.get("workflowStatus").asText());
    }
}
