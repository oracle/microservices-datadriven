// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.model;

import java.time.Instant;
import java.util.UUID;

/** Metadata for a ticket work event that failed processing and awaits operator action. */
public record FailedTicketEvent(
        UUID eventId,
        Long ticketId,
        String eventType,
        UUID correlationId,
        UUID causationId,
        int attemptCount,
        String failureType,
        boolean replayable,
        String status,
        Instant failedAt) {
}
