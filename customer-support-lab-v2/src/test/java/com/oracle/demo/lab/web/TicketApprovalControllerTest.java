// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.web;

import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.messaging.TicketReviewService;
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
        TicketReviewService reviews = mock(TicketReviewService.class);
        TicketApprovalController controller = new TicketApprovalController(store, reviews);
        var request = new TicketApproval.Request(UUID.randomUUID(), TicketApproval.Decision.APPROVED, "demo", null);
        when(reviews.record(42, request)).thenThrow(new IllegalArgumentException("invalid"));
        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> controller.record(42, request)).getStatusCode().value());
        doThrow(new TicketApprovalStore.ApprovalConflictException("not enriched")).when(reviews).record(42, request);
        assertEquals(409, assertThrows(ResponseStatusException.class,
                () -> controller.record(42, request)).getStatusCode().value());
        when(store.history(42)).thenThrow(new TicketApprovalStore.TicketNotFoundException(42));
        assertEquals(404, assertThrows(ResponseStatusException.class,
                () -> controller.history(42)).getStatusCode().value());
    }

    @Test
    void registersByDefault() {
        try (var context = new AnnotationConfigApplicationContext()) {
            context.registerBean(TicketApprovalStore.class, () -> mock(TicketApprovalStore.class));
            context.registerBean(TicketReviewService.class, () -> mock(TicketReviewService.class));
            context.register(TicketApprovalController.class);
            context.refresh();
            assertEquals(1,
                    context.getBeansOfType(TicketApprovalController.class).size());
        }
    }
}
