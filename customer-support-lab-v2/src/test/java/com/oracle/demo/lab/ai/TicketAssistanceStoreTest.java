// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.simple.JdbcClient;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TicketAssistanceStoreTest {
    @Test
    void savesSummaryAndScoredReferencesOnSuppliedConnection() throws Exception {
        Connection connection = mock(Connection.class);
        PreparedStatement assistance = mock(PreparedStatement.class);
        PreparedStatement addRelated = mock(PreparedStatement.class);
        PreparedStatement addPolicy = mock(PreparedStatement.class);
        when(connection.prepareStatement(anyString())).thenReturn(assistance, addRelated, addPolicy);
        RelatedTicket related = new RelatedTicket(7L, 0.82);
        PolicyMatch policy = new PolicyMatch("MFA_RECOVERY", "MFA recovery", 0.87);

        new TicketAssistanceStore(mock(JdbcClient.class)).save(connection, 42L,
                "User lost MFA access.", "chat-model", "ticket-summary-v1",
                List.of(related), List.of(policy));

        verify(assistance).setLong(1, 42L);
        verify(assistance).setString(2, "User lost MFA access.");
        verify(assistance).setString(3, "chat-model");
        verify(assistance).setString(4, "ticket-summary-v1");
        verify(assistance).executeUpdate();
        verify(addRelated).setLong(1, 42L);
        verify(addRelated).setLong(2, 7L);
        verify(addRelated).setDouble(3, 0.82);
        verify(addRelated).executeBatch();
        verify(addPolicy).setString(2, "MFA_RECOVERY");
        verify(addPolicy).setDouble(3, 0.87);
        verify(addPolicy).executeBatch();
    }
}
