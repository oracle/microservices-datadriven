// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import com.oracle.demo.lab.events.TicketEventOutcomeStore;
import com.oracle.demo.lab.events.TicketEventProducer;
import com.oracle.demo.lab.ticket.TicketReadRouter;
import com.oracle.demo.lab.ticket.TicketStore;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

class TicketControllerProfilesTest {
    @Test
    void eventsUsesSingleWriterAndReader() {
        assertControllers(new String[]{"events"});
    }

    @Test
    void optionalProfilesDoNotRegisterAnotherWriter() {
        assertControllers(new String[]{"events", "ai", "observability"});
    }

    private static void assertControllers(String[] profiles) {
        try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().setActiveProfiles(profiles);
            context.registerBean(TicketStore.class, () -> mock(TicketStore.class));
            context.registerBean(TicketReadRouter.class, () -> mock(TicketReadRouter.class));
            context.registerBean(TicketEventProducer.class, () -> mock(TicketEventProducer.class));
            context.registerBean(TicketEventOutcomeStore.class, () -> mock(TicketEventOutcomeStore.class));
            context.register(EventsController.class, TicketReadController.class);
            context.refresh();

            assertEquals(1, context.getBeansOfType(EventsController.class).size());
            assertEquals(1, context.getBeansOfType(TicketReadController.class).size());
        }
    }
}
