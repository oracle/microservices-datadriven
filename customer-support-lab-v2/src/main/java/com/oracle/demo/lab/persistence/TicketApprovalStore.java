// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.TicketApproval;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/** Append-only review persistence; the caller owns the write transaction. */
@Component
public class TicketApprovalStore {
    private final DataSource dataSource;

    public TicketApprovalStore(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public RecordedReview record(Connection connection, long ticketId, TicketApproval.Request request)
            throws SQLException {
        request.validate();
        // Serialize reviews and their action-ID retries with ticket processing.
        requireTicket(connection, ticketId, true);
        Optional<TicketApproval> previous = findAction(connection, request.actionId());
        if (previous.isPresent()) {
            TicketApproval saved = previous.get();
            if (saved.ticketId() != ticketId || saved.decision() != request.decision()
                    || !saved.actorId().equals(request.actorId()) || !Objects.equals(saved.reason(), request.reason())) {
                throw new ApprovalConflictException("actionId already belongs to a different review");
            }
            return new RecordedReview(saved, false);
        }

        try (var statement = connection.prepareStatement("""
                select a.summary, a.summary_model, a.prompt_version
                from ticket_assistance a join support_ticket t on t.id = a.ticket_id
                where a.ticket_id = ? and t.workflow_status = 'ENRICHED'
                """)) {
            statement.setLong(1, ticketId);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    throw new ApprovalConflictException("Ticket must have saved ENRICHED assistance before review");
                }
                String summary = rows.getString("summary");
                try (var insert = connection.prepareStatement("""
                        insert into ticket_approval_history
                            (action_id, ticket_id, decision, actor_id, reason, reviewed_summary,
                             summary_digest, summary_model, prompt_version)
                        values (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """)) {
                    JdbcUuidConverter.bind(insert, 1, request.actionId());
                    insert.setLong(2, ticketId);
                    insert.setString(3, request.decision().name());
                    insert.setString(4, request.actorId());
                    insert.setString(5, request.reason());
                    insert.setString(6, summary);
                    insert.setString(7, digest(summary));
                    insert.setString(8, rows.getString("summary_model"));
                    insert.setString(9, rows.getString("prompt_version"));
                    insert.executeUpdate();
                }
            }
        }
        return new RecordedReview(findAction(connection, request.actionId()).orElseThrow(), true);
    }

    public record RecordedReview(TicketApproval approval, boolean created) {
    }

    public List<TicketApproval> history(long ticketId) {
        try (Connection connection = dataSource.getConnection()) {
            requireTicket(connection, ticketId, false);
            try (var statement = connection.prepareStatement("""
                    select * from ticket_approval_history where ticket_id = ? order by decided_at, action_id
                    """)) {
                statement.setLong(1, ticketId);
                try (ResultSet rows = statement.executeQuery()) {
                    List<TicketApproval> history = new ArrayList<>();
                    while (rows.next()) {
                        history.add(map(rows));
                    }
                    return history;
                }
            }
        } catch (SQLException error) {
            throw new IllegalStateException("Could not read ticket approval history", error);
        }
    }

    private static void requireTicket(Connection connection, long ticketId, boolean lock) throws SQLException {
        try (var statement = connection.prepareStatement(
                "select id from support_ticket where id = ?" + (lock ? " for update" : ""))) {
            statement.setLong(1, ticketId);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    throw new TicketNotFoundException(ticketId);
                }
            }
        }
    }

    private static Optional<TicketApproval> findAction(Connection connection, UUID actionId) throws SQLException {
        try (var statement = connection.prepareStatement("select * from ticket_approval_history where action_id = ?")) {
            JdbcUuidConverter.bind(statement, 1, actionId);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? Optional.of(map(rows)) : Optional.empty();
            }
        }
    }

    private static TicketApproval map(ResultSet row) throws SQLException {
        return new TicketApproval(JdbcUuidConverter.read(row, "action_id"), row.getLong("ticket_id"),
                TicketApproval.Decision.valueOf(row.getString("decision")), row.getString("actor_id"),
                row.getString("reason"), row.getString("reviewed_summary"), row.getString("summary_digest"),
                row.getString("summary_model"), row.getString("prompt_version"),
                row.getTimestamp("decided_at").toLocalDateTime().toInstant(ZoneOffset.UTC));
    }

    static String digest(String summary) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(summary.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 is unavailable", error);
        }
    }

    public static final class ApprovalConflictException extends RuntimeException {
        public ApprovalConflictException(String message) { super(message); }
    }

    public static final class TicketNotFoundException extends RuntimeException {
        public TicketNotFoundException(long ticketId) { super("Ticket not found: " + ticketId); }
    }
}
