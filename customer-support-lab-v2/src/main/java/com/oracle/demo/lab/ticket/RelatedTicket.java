// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

/** A scored reference to another support ticket. */
public record RelatedTicket(long relatedTicketId, double score) {
}
