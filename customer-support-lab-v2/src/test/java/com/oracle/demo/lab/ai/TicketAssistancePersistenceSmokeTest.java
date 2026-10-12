// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
import com.oracle.demo.lab.persistence.TicketStore;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Opt-in check against a disposable schema prepared by scripts/setup-lab.sh. */
class TicketAssistancePersistenceSmokeTest {
    @Test
    @EnabledIfEnvironmentVariable(named = "LAB_DB_SMOKE_TEST", matches = "true")
    void persistsAndReadsAssistanceOnOneOracleTransaction() throws Exception {
        try (Connection connection = DriverManager.getConnection(
                required("LAB_SMOKE_JDBC_URL"), required("LAB_SMOKE_USERNAME"),
                required("LAB_SMOKE_PASSWORD"))) {
            connection.setAutoCommit(false);
            try {
                long relatedId = insertTicket(connection, "Earlier MFA recovery");
                long ticketId = insertTicket(connection, "Lost authenticator");
                JdbcClient jdbc = JdbcClient.create(new SingleConnectionDataSource(connection, true));
                TicketStore tickets = new TicketStore(jdbc);
                TicketAssistanceStore assistance = new TicketAssistanceStore(jdbc);
                RelatedTicket related = new RelatedTicket(relatedId, 0.82);
                float[] embedding = new float[1536];
                embedding[0] = 1.0f;

                tickets.saveEnrichment(connection, ticketId, embedding);
                assistance.save(connection, ticketId, "Use the approved MFA recovery flow.",
                        "smoke-chat-model", TicketSummarizer.PROMPT_VERSION,
                        List.of(related), List.of(new PolicyMatch("MFA_RECOVERY", "MFA recovery", 0.87)));

                TicketAssistance saved = assistance.findByTicketId(ticketId).orElseThrow();
                assertEquals("Use the approved MFA recovery flow.", saved.summary());
                assertEquals("smoke-chat-model", saved.summaryModel());
                assertEquals(relatedId, saved.similarTickets().getFirst().relatedTicketId());
                assertEquals("MFA_RECOVERY", saved.policies().getFirst().policyId());
                try (PreparedStatement statement = connection.prepareStatement(
                        "select workflow_status, embedding from support_ticket where id = ?")) {
                    statement.setLong(1, ticketId);
                    try (ResultSet row = statement.executeQuery()) {
                        row.next();
                        assertEquals("ENRICHED", row.getString("workflow_status"));
                        assertEquals(1536, row.getObject("embedding", float[].class).length);
                    }
                }
            } finally {
                connection.rollback();
            }
            try (PreparedStatement statement = connection.prepareStatement("""
                    select count(*) from support_ticket
                    where title in ('Earlier MFA recovery', 'Lost authenticator')
                    """);
                 ResultSet rows = statement.executeQuery()) {
                rows.next();
                assertEquals(0, rows.getLong(1));
            }
        }
    }

    private static long insertTicket(Connection connection, String title) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                insert into support_ticket (title, description, workflow_status)
                values (?, 'Smoke test only', 'RECEIVED')
                """, new String[]{"id"})) {
            statement.setString(1, title);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                keys.next();
                return keys.getLong(1);
            }
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
