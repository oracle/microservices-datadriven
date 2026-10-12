// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.processing;

import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.model.SupportTicket;

import java.sql.Connection;

/**
 * Interface for processing consumed ticket events.
 * Implemented in {@link LogEventProcessor} and {@link GenAIEventProcessor}.
 */
public interface TicketEventProcessor {
    void processRecord(Connection conn, TicketWorkEvent event, SupportTicket ticket);
}
