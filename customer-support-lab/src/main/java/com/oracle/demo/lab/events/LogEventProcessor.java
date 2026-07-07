// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ticket.SupportTicket;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.Connection;

@Component
@Profile("!ai")
public class LogEventProcessor implements TicketEventProcessor {
    private static final Logger log = LoggerFactory.getLogger(LogEventProcessor.class.getName());

    @Override
    public void processRecord(Connection conn, SupportTicket ticket) {
        log.info("Processing Ticket Event: {}", ticket);
    }
}
