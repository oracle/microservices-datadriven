// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.messaging.TicketEventProducer;
import com.oracle.demo.lab.persistence.TicketReadRouter;
import com.oracle.demo.lab.persistence.TicketStore;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

class TicketControllerConfigurationTest {
    @Test
    void defaultStartupUsesSingleWriterAndReader() {
        try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {

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
