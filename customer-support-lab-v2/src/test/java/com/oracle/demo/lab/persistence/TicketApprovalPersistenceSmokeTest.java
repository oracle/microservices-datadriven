// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.TicketApproval;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.sql.SQLException;
import java.sql.Types;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/** Leaves a committed fixture because blockchain rows cannot be deleted during retention. */
class TicketApprovalPersistenceSmokeTest {
    @Test
    @EnabledIfEnvironmentVariable(named = "LAB_BLOCKCHAIN_SMOKE_TEST", matches = "true")
    void commitsDeduplicatesRejectsMutationAndVerifiesBlockchain() throws Exception {
        var source = new DriverManagerDataSource(required("LAB_SMOKE_JDBC_URL"),
                required("LAB_SMOKE_USERNAME"), required("LAB_SMOKE_PASSWORD"));
        long ticketId;
        try (var connection = source.getConnection()) {
            connection.setAutoCommit(false);
            try {
                try (var ticket = connection.prepareStatement("""
                        insert into support_ticket(title, description, workflow_status)
                        values ('Blockchain smoke test', 'Disposable test fixture', 'ENRICHED')
                        """, new String[]{"id"})) {
                    ticket.executeUpdate();
                    try (var keys = ticket.getGeneratedKeys()) {
                        assertTrue(keys.next());
                        ticketId = keys.getLong(1);
                    }
                }
                try (var assistance = connection.prepareStatement("""
                        insert into ticket_assistance(ticket_id, summary, summary_model, prompt_version)
                        values (?, 'Review the recovery request.', 'smoke-model', 'smoke-prompt')
                        """)) {
                    assistance.setLong(1, ticketId);
                    assistance.executeUpdate();
                }
                connection.commit();
            } catch (Exception error) {
                connection.rollback();
                throw error;
            }
        }
        var store = new TicketApprovalStore(source);
        var request = new TicketApproval.Request(UUID.randomUUID(), TicketApproval.Decision.APPROVED,
                "smoke-reviewer", "Reviewed manually");
        TicketApproval saved = record(store, source, ticketId, request);
        assertEquals(saved, record(store, source, ticketId, request));
        assertEquals(1, store.history(ticketId).size());
        assertEquals(TicketApprovalStore.digest(saved.reviewedSummary()), saved.summaryDigest());
        assertThrows(TicketApprovalStore.ApprovalConflictException.class, () -> record(store, source, ticketId,
                new TicketApproval.Request(request.actionId(), TicketApproval.Decision.REJECTED,
                        request.actorId(), request.reason())));

        try (var connection = source.getConnection()) {
            connection.setAutoCommit(false);
            // Roll back an append before commit, then confirm it left no durable row.
            try (var insert = connection.prepareStatement("""
                    insert into ticket_approval_history
                        (action_id, ticket_id, decision, actor_id, reviewed_summary,
                         summary_digest, summary_model, prompt_version)
                    select ?, ticket_id, decision, actor_id, reviewed_summary,
                           summary_digest, summary_model, prompt_version
                    from ticket_approval_history where ticket_id = ?
                    """)) {
                JdbcUuidConverter.bind(insert, 1, UUID.randomUUID());
                insert.setLong(2, ticketId);
                assertEquals(1, insert.executeUpdate());
            }
            connection.rollback();
            for (String sql : new String[]{
                    "update ticket_approval_history set decision = 'REJECTED' where ticket_id = ?",
                    "delete from ticket_approval_history where ticket_id = ?"}) {
                try (var mutate = connection.prepareStatement(sql)) {
                    mutate.setLong(1, ticketId);
                    assertThrows(SQLException.class, mutate::executeUpdate);
                }
                connection.rollback();
            }
            try (var verify = connection.prepareCall("""
                    begin dbms_blockchain_table.verify_rows(
                        schema_name => user, table_name => 'TICKET_APPROVAL_HISTORY',
                        number_of_rows_verified => ?, verify_signature => false); end;
                    """)) {
                verify.registerOutParameter(1, Types.NUMERIC);
                verify.execute();
                try (var count = connection.prepareStatement("select count(*) from ticket_approval_history");
                     var rows = count.executeQuery()) {
                    assertTrue(rows.next());
                    assertEquals(rows.getLong(1), verify.getLong(1));
                }
            }
        }
        assertEquals(1, store.history(ticketId).size());
    }

    private static TicketApproval record(TicketApprovalStore store, javax.sql.DataSource source,
                                         long ticketId, TicketApproval.Request request) throws Exception {
        try (var connection = source.getConnection()) {
            connection.setAutoCommit(false);
            try {
                TicketApproval saved = store.record(connection, ticketId, request).approval();
                connection.commit();
                return saved;
            } catch (Exception failure) {
                connection.rollback();
                throw failure;
            }
        }
    }

    private static String required(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException(name + " is required for the blockchain smoke test");
        }
        return value;
    }
}
