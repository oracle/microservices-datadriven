// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.persistence.TicketStore;
import com.oracle.demo.lab.model.SupportTicket;

import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketStoreSqlTest {
    private final TicketStore store = new TicketStore(null);

    @Test
    void insertReturnsGeneratedTicketId() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet keys = mock(ResultSet.class);
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Lost MFA authenticator");
        ticket.setDescription("How can I recover access safely?");
        when(connection.prepareStatement(anyString(), any(String[].class))).thenReturn(statement);
        when(statement.getGeneratedKeys()).thenReturn(keys);
        when(keys.next()).thenReturn(true);
        when(keys.getLong(1)).thenReturn(42L);

        assertEquals(42L, store.insert(connection, ticket));
        verify(statement).setString(1, ticket.getTitle());
        verify(statement).setString(2, ticket.getDescription());
        verify(statement).setString(3, "RECEIVED");
        verify(statement).executeUpdate();
    }

    @Test
    void reviewFeedbackUpdatesOnlyAnEnrichedTicket() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeUpdate()).thenReturn(1, 0);

        store.addReviewFeedback(connection, 42L, "Test tenant, not production.");

        verify(statement).setString(1, "Test tenant, not production.");
        verify(statement).setString(2, "Test tenant, not production.");
        verify(statement).setLong(3, 42L);
        assertThrows(IllegalStateException.class,
                () -> store.addReviewFeedback(connection, 42L, "Another correction."));
    }

    @Test
    void replayResetRequiresFailedTicket() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeUpdate()).thenReturn(0);

        assertThrows(IllegalStateException.class, () -> store.resetFailedForReplay(connection, 42L));
        verify(statement).setLong(1, 42L);
    }

    @Test
    void replayResetUpdatesFailedTicket() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeUpdate()).thenReturn(1);

        store.resetFailedForReplay(connection, 42L);

        verify(statement).setLong(1, 42L);
        verify(statement).executeUpdate();
    }
}
