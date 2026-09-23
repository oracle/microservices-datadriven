// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import java.util.Objects;

public class RelatedTicket {
    private Long relatedTicketId;

    public Long getRelatedTicketId() {
        return relatedTicketId;
    }

    public void setRelatedTicketId(Long relatedTicketId) {
        this.relatedTicketId = relatedTicketId;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        RelatedTicket that = (RelatedTicket) o;
        return Objects.equals(relatedTicketId, that.relatedTicketId);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(relatedTicketId);
    }
}
