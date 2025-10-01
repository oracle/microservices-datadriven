package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ticket.SupportTicket;

import java.sql.Connection;

/**
 * Interface for processing consumed ticket events.
 * Implemented in {@link LogEventProcessor} and {@link GenAIEventProcessor}.
 */
public interface TicketEventProcessor {
    void processRecord(Connection conn, SupportTicket ticket);
}
