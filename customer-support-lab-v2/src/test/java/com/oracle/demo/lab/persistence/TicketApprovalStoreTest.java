// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.TicketApproval;
import org.junit.jupiter.api.Test;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class TicketApprovalStoreTest {
    private final DataSource source = mock(DataSource.class);
    private final TicketApprovalStore store = new TicketApprovalStore(source);
    private final Connection connection = mock(Connection.class);
    private final UUID actionId = UUID.randomUUID();
    private final TicketApproval.Request request =
            new TicketApproval.Request(actionId, TicketApproval.Decision.APPROVED, "demo-reviewer", null);

    @Test
    void validatesInputBeforeDatabaseAccessAndRequiresRejectionFeedback() {
        assertThrows(IllegalArgumentException.class, () -> store.record(connection, 42,
                new TicketApproval.Request(null, null, "", null)));
        assertThrows(IllegalArgumentException.class, () -> store.record(connection, 42,
                new TicketApproval.Request(actionId, TicketApproval.Decision.REJECTED, "demo-reviewer", "  ")));
        verifyNoInteractions(source, connection);
        assertNull(new TicketApproval.Request(actionId, request.decision(), request.actorId(), "").reason());
    }

    @Test
    void repeatedActionReturnsSavedReviewWithoutAnotherInsert() throws Exception {
        prepareExistingAction("APPROVED");

        TicketApprovalStore.RecordedReview result = store.record(connection, 42, request);

        assertFalse(result.created());
        assertEquals(actionId, result.approval().actionId());
        assertEquals("saved summary", result.approval().reviewedSummary());
        verify(connection, times(2)).prepareStatement(anyString());
        verify(connection, never()).commit();
        verifyNoInteractions(source);
    }

    @Test
    void reusingActionWithDifferentDecisionIsRejected() throws Exception {
        prepareExistingAction("REJECTED");
        assertThrows(TicketApprovalStore.ApprovalConflictException.class,
                () -> store.record(connection, 42, request));
    }

    @Test
    void absentTicketFailsBeforeReadingAssistance() throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeQuery()).thenReturn(mock(ResultSet.class));

        assertThrows(TicketApprovalStore.TicketNotFoundException.class,
                () -> store.record(connection, 42, request));
        verify(connection, times(1)).prepareStatement(anyString());
    }

    @Test
    void newReviewSnapshotsSavedAssistanceOnCallerConnection() throws Exception {
        ResultSet saved = prepareExistingAction("APPROVED");
        PreparedStatement ticket = ticketStatement();
        PreparedStatement missingAction = mock(PreparedStatement.class);
        when(missingAction.executeQuery()).thenReturn(mock(ResultSet.class));
        PreparedStatement assistance = mock(PreparedStatement.class);
        ResultSet summary = mock(ResultSet.class);
        when(assistance.executeQuery()).thenReturn(summary);
        when(summary.next()).thenReturn(true);
        when(summary.getString("summary")).thenReturn("saved summary");
        when(summary.getString("summary_model")).thenReturn("chat-model");
        when(summary.getString("prompt_version")).thenReturn("prompt-v1");
        PreparedStatement insert = mock(PreparedStatement.class);
        PreparedStatement readBack = mock(PreparedStatement.class);
        when(readBack.executeQuery()).thenReturn(saved);
        when(connection.prepareStatement(anyString())).thenReturn(ticket, missingAction, assistance, insert, readBack);

        assertTrue(store.record(connection, 42, request).created());

        verify(insert).setString(6, "saved summary");
        verify(insert).setString(7, TicketApprovalStore.digest("saved summary"));
        verify(insert).setString(8, "chat-model");
        verify(insert).executeUpdate();
        verify(connection, never()).commit();
        verify(connection, never()).close();
    }

    @Test
    void summaryDigestUsesSha256OfExactUtf8Text() {
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                TicketApprovalStore.digest("abc"));
        assertNotEquals(TicketApprovalStore.digest("summary"), TicketApprovalStore.digest("summary\n"));
    }

    @Test
    void pendingTicketCannotReceiveAnotherNewReview() throws Exception {
        PreparedStatement noAction = mock(PreparedStatement.class);
        when(noAction.executeQuery()).thenReturn(mock(ResultSet.class));
        PreparedStatement noAssistance = mock(PreparedStatement.class);
        when(noAssistance.executeQuery()).thenReturn(mock(ResultSet.class));
        PreparedStatement ticket = ticketStatement();
        when(connection.prepareStatement(anyString())).thenReturn(ticket, noAction, noAssistance);

        assertThrows(TicketApprovalStore.ApprovalConflictException.class,
                () -> store.record(connection, 42, request));
    }

    private PreparedStatement ticketStatement() throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet row = mock(ResultSet.class);
        when(statement.executeQuery()).thenReturn(row);
        when(row.next()).thenReturn(true);
        return statement;
    }

    private ResultSet prepareExistingAction(String decision) throws Exception {
        PreparedStatement ticket = ticketStatement();
        PreparedStatement action = mock(PreparedStatement.class);
        ResultSet row = mock(ResultSet.class);
        when(action.executeQuery()).thenReturn(row);
        when(row.next()).thenReturn(true);
        when(row.getBytes("action_id")).thenReturn(JdbcUuidConverter.toBytes(actionId));
        when(row.getLong("ticket_id")).thenReturn(42L);
        when(row.getString("decision")).thenReturn(decision);
        when(row.getString("actor_id")).thenReturn("demo-reviewer");
        when(row.getString("reviewed_summary")).thenReturn("saved summary");
        when(row.getTimestamp("decided_at")).thenReturn(Timestamp.valueOf("2026-10-13 12:00:00"));
        when(connection.prepareStatement(anyString())).thenReturn(ticket, action);
        return row;
    }
}
