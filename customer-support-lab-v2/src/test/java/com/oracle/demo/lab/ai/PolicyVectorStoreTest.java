// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PolicyVectorStoreTest {
    @Test
    void returnsScoredPolicyReferences() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet result = mock(ResultSet.class);
        when(connection.prepareStatement(any(String.class))).thenReturn(statement);
        when(statement.executeQuery()).thenReturn(result);
        when(result.next()).thenReturn(true, false);
        when(result.getString("policy_id")).thenReturn("MFA_RECOVERY");
        when(result.getString("title")).thenReturn("MFA recovery");
        when(result.getDouble("score")).thenReturn(0.87);

        var matches = new PolicyVectorStore().search(connection, new float[1536]);

        assertEquals(1, matches.size());
        assertEquals(new PolicyMatch("MFA_RECOVERY", "MFA recovery", 0.87), matches.getFirst());
        verify(statement).setObject(eq(1), any(VECTOR.class), eq(OracleType.VECTOR.getVendorTypeNumber()));
        verify(statement).setDouble(2, 0.2);
    }
}
