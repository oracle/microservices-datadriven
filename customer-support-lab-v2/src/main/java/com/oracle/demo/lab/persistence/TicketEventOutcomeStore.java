// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.FailedTicketEvent;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.model.TicketStatus;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Persists completed-event IDs and failed-event records in the TxEventQ transaction. */
@Component
public class TicketEventOutcomeStore {
    private final JdbcClient jdbcClient;

    public TicketEventOutcomeStore(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public boolean hasOutcome(Connection connection, UUID eventId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                """
                select 1 from dual where
                    exists (select 1 from ticket_event_processed where event_id = ?)
                    or exists (select 1 from failed_ticket_event where event_id = ?)
                """)) {
            JdbcUuidConverter.bind(statement, 1, eventId);
            JdbcUuidConverter.bind(statement, 2, eventId);
            try (ResultSet result = statement.executeQuery()) {
                return result.next();
            }
        }
    }

    public void markProcessed(Connection connection, TicketWorkEvent event) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                insert into ticket_event_processed (event_id, ticket_id, processed_at)
                values (?, ?, systimestamp)
                """)) {
            JdbcUuidConverter.bind(statement, 1, event.getEventId());
            statement.setObject(2, event.getTicketId());
            statement.executeUpdate();
        }
    }

    public void recordFailure(Connection connection, TicketWorkEvent event,
                              int attemptCount, String failureType) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                insert into failed_ticket_event
                    (event_id, schema_version, ticket_id, event_type, correlation_id, causation_id,
                     attempt_count, failure_type, status, failed_at)
                values (?, ?, ?, ?, ?, ?, ?, ?, 'FAILED', systimestamp)
                """)) {
            JdbcUuidConverter.bind(statement, 1, event.getEventId());
            statement.setInt(2, event.getSchemaVersion());
            statement.setObject(3, event.getTicketId());
            statement.setString(4, event.getEventType());
            JdbcUuidConverter.bind(statement, 5, event.getCorrelationId());
            JdbcUuidConverter.bind(statement, 6, event.getCausationId());
            statement.setInt(7, attemptCount);
            statement.setString(8, failureType);
            statement.executeUpdate();
        }
    }

    public List<FailedTicketEvent> findFailed() {
        return jdbcClient.sql("""
                select f.event_id, f.schema_version, f.ticket_id, f.event_type,
                       f.correlation_id, f.causation_id, f.attempt_count,
                       f.failure_type, f.status, f.failed_at, t.workflow_status as ticket_status
                from failed_ticket_event f
                left join support_ticket t on t.id = f.ticket_id
                where f.status = 'FAILED' order by f.failed_at
                """)
                .query((rs, rowNum) -> mapFailure(rs))
                .list();
    }

    public Optional<TicketWorkEvent> lockFailedEvent(Connection connection, UUID eventId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                select event_id, schema_version, ticket_id, event_type, correlation_id, causation_id
                from failed_ticket_event where event_id = ? and status = 'FAILED'
                for update
                """)) {
            JdbcUuidConverter.bind(statement, 1, eventId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    return Optional.empty();
                }
                TicketWorkEvent event = new TicketWorkEvent();
                event.setSchemaVersion(result.getInt("schema_version"));
                event.setEventId(JdbcUuidConverter.read(result, "event_id"));
                event.setTicketId(nullableTicketId(result));
                event.setEventType(result.getString("event_type"));
                event.setCorrelationId(JdbcUuidConverter.read(result, "correlation_id"));
                event.setCausationId(JdbcUuidConverter.read(result, "causation_id"));
                return Optional.of(event);
            }
        }
    }

    public void markReplayed(Connection connection, UUID eventId) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                update failed_ticket_event set status = 'REPLAYED'
                where event_id = ? and status = 'FAILED'
                """)) {
            JdbcUuidConverter.bind(statement, 1, eventId);
            if (statement.executeUpdate() != 1) {
                throw new SQLException("Failed event is no longer available for replay: " + eventId);
            }
        }
    }

    private static FailedTicketEvent mapFailure(ResultSet rs) throws SQLException {
        Timestamp failedAt = rs.getTimestamp("failed_at");
        Long ticketId = nullableTicketId(rs);
        String eventType = rs.getString("event_type");
        boolean replayable = TicketWorkEvent.isSupportedEnvelope(
                rs.getInt("schema_version"), eventType, ticketId)
                && TicketStatus.FAILED.name().equals(rs.getString("ticket_status"));
        return new FailedTicketEvent(
                JdbcUuidConverter.read(rs, "event_id"),
                ticketId,
                eventType,
                JdbcUuidConverter.read(rs, "correlation_id"),
                JdbcUuidConverter.read(rs, "causation_id"),
                rs.getInt("attempt_count"),
                rs.getString("failure_type"),
                replayable,
                rs.getString("status"),
                failedAt == null ? null : failedAt.toInstant());
    }

    private static Long nullableTicketId(ResultSet result) throws SQLException {
        long ticketId = result.getLong("ticket_id");
        return result.wasNull() ? null : ticketId;
    }
}
