// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.ticket.RelatedTicket;

import java.time.Instant;
import java.util.List;

/** Persisted recommendations for a human support agent, never an automatic decision. */
public record TicketAssistance(
        long ticketId,
        String summary,
        String summaryModel,
        String promptVersion,
        Instant generatedAt,
        List<RelatedTicket> similarTickets,
        List<PolicyMatch> policies) {
}
