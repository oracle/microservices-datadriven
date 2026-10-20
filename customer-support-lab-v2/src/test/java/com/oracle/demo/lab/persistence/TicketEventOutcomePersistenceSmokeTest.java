// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.TicketWorkEvent;

import com.oracle.demo.lab.persistence.JdbcUuidConverter;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Opt-in Oracle check that a redelivered failure cannot reopen a replayed event. */
class TicketEventOutcomePersistenceSmokeTest {
    @Test
    @EnabledIfEnvironmentVariable(named = "LAB_DB_SMOKE_TEST", matches = "true")
    void completedAndFailedEventsBothBlockDuplicateProcessing() throws Exception {
        try (Connection connection = DriverManager.getConnection(
                required("LAB_SMOKE_JDBC_URL"), required("LAB_SMOKE_USERNAME"),
                required("LAB_SMOKE_PASSWORD"))) {
            connection.setAutoCommit(false);
            TicketEventOutcomeStore store = new TicketEventOutcomeStore(
                    JdbcClient.create(new SingleConnectionDataSource(connection, true)));
            TicketWorkEvent completed = TicketWorkEvent.submitted(42L, null);
            TicketWorkEvent failed = TicketWorkEvent.submitted(43L, null);
            try {
                assertFalse(store.hasOutcome(connection, completed.getEventId()));
                assertFalse(store.hasOutcome(connection, failed.getEventId()));

                store.markProcessed(connection, completed);
                store.recordFailure(connection, failed, 3, "DemoFailureException");
                assertTrue(store.hasOutcome(connection, completed.getEventId()));
                assertTrue(store.hasOutcome(connection, failed.getEventId()));

                store.markReplayed(connection, failed.getEventId());
                assertTrue(store.hasOutcome(connection, failed.getEventId()));
                assertThrows(SQLException.class,
                        () -> store.recordFailure(connection, failed, 1, "DemoFailureException"));
                try (PreparedStatement statement = connection.prepareStatement(
                        "select status from failed_ticket_event where event_id = ?")) {
                    JdbcUuidConverter.bind(statement, 1, failed.getEventId());
                    try (ResultSet row = statement.executeQuery()) {
                        assertTrue(row.next());
                        assertEquals("REPLAYED", row.getString(1));
                    }
                }
            } finally {
                connection.rollback();
            }
            assertFalse(store.hasOutcome(connection, completed.getEventId()));
            assertFalse(store.hasOutcome(connection, failed.getEventId()));
        }
    }

    private static String required(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(name + " is required for the opt-in database smoke test");
        }
        return value;
    }
}
