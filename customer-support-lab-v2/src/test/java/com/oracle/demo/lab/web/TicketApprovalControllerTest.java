// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.web;

import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TicketApprovalControllerTest {
    @Test
    void mapsInvalidInputMissingTicketAndIneligibleReview() {
        TicketApprovalStore store = mock(TicketApprovalStore.class);
        TicketApprovalController controller = new TicketApprovalController(store);
        var request = new TicketApproval.Request(UUID.randomUUID(), TicketApproval.Decision.APPROVED, "demo", null);
        when(store.record(42, request)).thenThrow(new IllegalArgumentException("invalid"));
        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> controller.record(42, request)).getStatusCode().value());
        doThrow(new TicketApprovalStore.ApprovalConflictException("not enriched")).when(store).record(42, request);
        assertEquals(409, assertThrows(ResponseStatusException.class,
                () -> controller.record(42, request)).getStatusCode().value());
        when(store.history(42)).thenThrow(new TicketApprovalStore.TicketNotFoundException(42));
        assertEquals(404, assertThrows(ResponseStatusException.class,
                () -> controller.history(42)).getStatusCode().value());
    }

    @Test
    void requiresBothEventsAndBlockchainProfiles() {
        for (String[] profiles : new String[][]{{"events"}, {"blockchain"}, {"events", "blockchain"}}) {
            try (var context = new AnnotationConfigApplicationContext()) {
                context.getEnvironment().setActiveProfiles(profiles);
                context.registerBean(TicketApprovalStore.class, () -> mock(TicketApprovalStore.class));
                context.register(TicketApprovalController.class);
                context.refresh();
                assertEquals(profiles.length == 2 ? 1 : 0,
                        context.getBeansOfType(TicketApprovalController.class).size());
            }
        }
    }
}
