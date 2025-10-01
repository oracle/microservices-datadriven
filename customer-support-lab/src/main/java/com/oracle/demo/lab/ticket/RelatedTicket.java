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
