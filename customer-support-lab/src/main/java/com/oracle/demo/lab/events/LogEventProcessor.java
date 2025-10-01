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
