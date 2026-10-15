// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.model;

import java.time.Instant;
import java.util.UUID;

/** A human review of a saved summary; actorId is self-declared in this unauthenticated lab. */
public record TicketApproval(UUID actionId, long ticketId, Decision decision, String actorId,
                             String reason, String reviewedSummary, String summaryDigest,
                             String summaryModel, String promptVersion, Instant decidedAt) {
    public enum Decision { APPROVED, REJECTED }

    public record Request(UUID actionId, Decision decision, String actorId, String reason) {
        public Request {
            // Oracle stores an empty VARCHAR2 as NULL; preserve replay equality.
            if (reason != null && reason.isEmpty()) {
                reason = null;
            }
        }

        public void validate() {
            if (actionId == null || decision == null || actorId == null || actorId.isBlank()
                    || actorId.codePointCount(0, actorId.length()) > 128
                    || (reason != null && reason.codePointCount(0, reason.length()) > 1000)) {
                throw new IllegalArgumentException(
                        "Supply an actionId UUID, APPROVED/REJECTED decision, actorId (1–128 characters), "
                                + "and optional reason (up to 1000 characters)");
            }
            if (decision == Decision.REJECTED && (reason == null || reason.isBlank())) {
                throw new IllegalArgumentException("A REJECTED review requires feedback in reason");
            }
        }
    }
}
