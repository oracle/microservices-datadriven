// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.bmc.model.BmcException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TicketEventRetryTest {
    @Test
    void retriesOciRateLimitsAndServerFailuresButNotBadRequests() {
        assertTrue(TicketEventConsumer.isRetryable(
                new BmcException(429, "TooManyRequests", "Slow down", "request-id")));
        assertTrue(TicketEventConsumer.isRetryable(
                new BmcException(503, "ServiceUnavailable", "Try later", "request-id")));
        assertFalse(TicketEventConsumer.isRetryable(
                new BmcException(400, "InvalidParameter", "Bad request", "request-id")));
    }
}
