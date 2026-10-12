// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;

import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

@Component
public class TicketStore {
    private static final String UPDATE_WORKFLOW_STATUS_SQL =
            "update support_ticket set workflow_status = ? where id = ?";

    private final JdbcClient jdbcClient;

    public TicketStore(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public List<SupportTicket> getAllTickets() {
        return jdbcClient.sql("select id, title, description, workflow_status from support_ticket")
                .query((rows, rowNumber) -> new SupportTicket(rows)).list();
    }

    public Optional<SupportTicket> findById(Long id) {
        return jdbcClient.sql("select id, title, description, workflow_status from support_ticket where id = ?")
                .param(id)
                .query((rows, rowNumber) -> new SupportTicket(rows)).optional();
    }

    public long insert(Connection connection, SupportTicket ticket) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                insert into support_ticket (title, description, workflow_status)
                values (?, ?, ?)
                """, new String[]{"id"})) {
            statement.setString(1, ticket.getTitle());
            statement.setString(2, ticket.getDescription());
            statement.setString(3, ticket.getWorkflowStatus().name());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new SQLException("Creating ticket failed, no ID obtained.");
                }
                return keys.getLong(1);
            }
        }
    }

    public void resetFailedForReplay(Connection connection, long ticketId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                update support_ticket set workflow_status = 'RECEIVED'
                where id = ? and workflow_status = 'FAILED'
                """)) {
            statement.setLong(1, ticketId);
            if (statement.executeUpdate() != 1) {
                throw new IllegalStateException("Failed ticket is no longer available for replay");
            }
        }
    }

    public void saveEnrichment(Connection conn, long ticketId, float[] embedding) {
        try (PreparedStatement ps = conn.prepareStatement("""
                update support_ticket set embedding = ?, workflow_status = 'ENRICHED' where id = ?
                """)) {
            ps.setObject(1, VECTOR.ofFloat32Values(embedding), OracleType.VECTOR.getVendorTypeNumber());
            ps.setLong(2, ticketId);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("Updating ticket enrichment failed; ticket not found: " + ticketId);
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not persist ticket enrichment", e);
        }
    }

    public void updateWorkflowStatus(Connection conn, Long ticketId, TicketStatus status) {
        try (PreparedStatement ps = conn.prepareStatement(UPDATE_WORKFLOW_STATUS_SQL)) {
            ps.setString(1, status.name());
            ps.setLong(2, ticketId);
            if (ps.executeUpdate() == 0) {
                throw new SQLException("Updating ticket workflow status failed; ticket not found: " + ticketId);
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
