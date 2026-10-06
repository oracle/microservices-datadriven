// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TrueCacheTicketReaderTest {
    private final Connection connection = mock(Connection.class);
    private final PreparedStatement statement = mock(PreparedStatement.class);
    private final ResultSet row = mock(ResultSet.class);

    @Test
    void acceptsExpectedCacheDatabase() throws Exception {
        stubDatabaseName("TRUEFREE");

        assertDoesNotThrow(() -> TrueCacheTicketReader.verifyCacheIdentity(connection, "truefree"));
    }

    @Test
    void rejectsPrimaryMisconfiguredAsCache() throws Exception {
        stubDatabaseName("FREE");

        SQLException error = assertThrows(SQLException.class,
                () -> TrueCacheTicketReader.verifyCacheIdentity(connection, "TRUEFREE"));

        assertTrue(error.getMessage().contains("connected to FREE"));
    }

    private void stubDatabaseName(String name) throws SQLException {
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(statement.executeQuery()).thenReturn(row);
        when(row.next()).thenReturn(true);
        when(row.getString(1)).thenReturn(name);
    }
}
