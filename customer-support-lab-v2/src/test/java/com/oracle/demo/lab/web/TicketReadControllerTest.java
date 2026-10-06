// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketReadRouter;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TicketReadControllerTest {
    @Test
    void preservesReadPathHeaderOnListAndCacheMiss() {
        TicketReadRouter reads = mock(TicketReadRouter.class);
        when(reads.all(null)).thenReturn(new TicketReadRouter.ReadResult<>(List.of(), "true-cache"));
        when(reads.byId(42L, "cache"))
                .thenReturn(new TicketReadRouter.ReadResult<>(Optional.empty(), "true-cache"));
        TicketReadController controller = new TicketReadController(reads);

        var list = controller.getAllTickets(null);
        var missing = controller.getTicket(42L, "cache");

        assertEquals("true-cache", list.getHeaders().getFirst("X-Read-Path"));
        assertEquals(List.of(), list.getBody());
        assertEquals(HttpStatus.NOT_FOUND, missing.getStatusCode());
        assertEquals("true-cache", missing.getHeaders().getFirst("X-Read-Path"));
    }

    @Test
    void returnsTicketFromRequestedPath() {
        TicketReadRouter reads = mock(TicketReadRouter.class);
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        when(reads.byId(42L, "primary"))
                .thenReturn(new TicketReadRouter.ReadResult<>(Optional.of(ticket), "primary"));

        var response = new TicketReadController(reads).getTicket(42L, "primary");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("primary", response.getHeaders().getFirst("X-Read-Path"));
        assertEquals(ticket, response.getBody());
    }
}
