// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.simple.JdbcClient;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketEventOutcomeStoreTest {
    private final TicketEventOutcomeStore store = new TicketEventOutcomeStore(mock(JdbcClient.class));
    private final Connection connection = mock(Connection.class);
    private final PreparedStatement statement = mock(PreparedStatement.class);

    @Test
    void duplicateCheckIncludesCompletedAndFailedEvents() throws Exception {
        ResultSet result = mock(ResultSet.class);
        UUID eventId = UUID.randomUUID();
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeQuery()).thenReturn(result);
        when(result.next()).thenReturn(true);

        assertTrue(store.hasOutcome(connection, eventId));

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(connection).prepareStatement(sql.capture());
        assertTrue(sql.getValue().contains("ticket_event_processed"));
        assertTrue(sql.getValue().contains("failed_ticket_event"));
        byte[] expected = JdbcUuidConverter.toBytes(eventId);
        verify(statement).setBytes(1, expected);
        verify(statement).setBytes(2, expected);
    }

    @Test
    void failureRecordingCannotUpdateAnExistingReplay() throws Exception {
        TicketWorkEvent event = TicketWorkEvent.submitted(42L, null);
        when(connection.prepareStatement(anyString())).thenReturn(statement);

        store.recordFailure(connection, event, 3, "DemoFailureException");

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(connection).prepareStatement(sql.capture());
        assertTrue(sql.getValue().stripLeading().startsWith("insert into failed_ticket_event"));
    }
}
