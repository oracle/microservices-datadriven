// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import java.sql.ResultSet;
import java.sql.SQLException;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class SupportTicket {
    private Long id;
    private String title;
    private String description;
    private TicketStatus workflowStatus = TicketStatus.RECEIVED;

    public SupportTicket() {
    }

    public SupportTicket(ResultSet rs) throws SQLException {
        this.id = rs.getLong("id");
        this.title = rs.getString("title");
        this.description = rs.getString("description");
        this.workflowStatus = TicketStatus.valueOf(rs.getString("workflow_status"));
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public TicketStatus getWorkflowStatus() {
        return workflowStatus;
    }

    public void setWorkflowStatus(TicketStatus workflowStatus) {
        this.workflowStatus = workflowStatus;
    }

    @Override
    public String toString() {
        return "SupportTicket{" +
                "id=" + id +
                ", workflowStatus=" + workflowStatus +
                '}';
    }
}
