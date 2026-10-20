// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.ai.TicketVectorStore;
import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketVectorStoreTest {
    @Test
    void preservesScoreOrderFromTheDatabase() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet result = mock(ResultSet.class);
        when(connection.prepareStatement(any(String.class))).thenReturn(statement);
        when(statement.executeQuery()).thenReturn(result);
        when(result.next()).thenReturn(true, true, false);
        when(result.getLong("id")).thenReturn(7L, 8L);
        when(result.getDouble("score")).thenReturn(0.91, 0.82);

        var matches = new TicketVectorStore().search(0.2, new float[1536], 42L, connection);

        assertEquals(2, matches.size());
        assertEquals(7L, matches.get(0).relatedTicketId());
        assertEquals(0.91, matches.get(0).score());
        assertEquals(8L, matches.get(1).relatedTicketId());
        assertEquals(0.82, matches.get(1).score());
        verify(connection).prepareStatement(contains("order by score desc"));
        verify(statement).setObject(eq(1), any(VECTOR.class), eq(OracleType.VECTOR.getVendorTypeNumber()));
        verify(statement).setLong(2, 42L);
    }
}
