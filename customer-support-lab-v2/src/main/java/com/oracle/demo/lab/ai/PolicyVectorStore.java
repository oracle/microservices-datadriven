// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Component
public class PolicyVectorStore {
    public List<PolicyMatch> search(Connection connection, float[] ticketEmbedding) {
        // The three-row demo corpus uses exact cosine search; an ANN index adds no value here.
        String sql = """
                select policy_id, title, score from (
                    select policy_id, title,
                           1 - vector_distance(embedding, ?, cosine) as score
                    from support_policy where embedding is not null
                ) where score >= ?
                order by score desc
                fetch first 3 rows only
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setObject(1, VECTOR.ofFloat32Values(ticketEmbedding),
                    OracleType.VECTOR.getVendorTypeNumber());
            statement.setDouble(2, 0.2);
            try (ResultSet result = statement.executeQuery()) {
                List<PolicyMatch> matches = new ArrayList<>();
                while (result.next()) {
                    matches.add(new PolicyMatch(result.getString("policy_id"),
                            result.getString("title"), result.getDouble("score")));
                }
                return matches;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not search support policies", e);
        }
    }
}
