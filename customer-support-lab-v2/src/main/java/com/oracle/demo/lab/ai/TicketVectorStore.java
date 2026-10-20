// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** Searches existing ticket embeddings for related support tickets. */
@Component
public class TicketVectorStore {
    public List<RelatedTicket> search(double minScore, float[] vector, Long ticketId, Connection connection) {
        final String searchQuery = """
                select id, title, resolution, score from (
                    select id, title, resolution, 1 - vector_distance(embedding, ?, cosine) as score
                    from support_ticket where id != ? and embedding is not null
                )
                where score >= ?
                order by score desc
                fetch first 5 rows only""";

        List<RelatedTicket> matches = new ArrayList<>();
        try (PreparedStatement stmt = connection.prepareStatement(searchQuery)) {
            VECTOR v = VECTOR.ofFloat32Values(vector);
            stmt.setObject(1, v, OracleType.VECTOR.getVendorTypeNumber());
            stmt.setLong(2, ticketId);
            stmt.setObject(3, minScore, OracleType.NUMBER.getVendorTypeNumber());
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    matches.add(new RelatedTicket(rs.getLong("id"), rs.getDouble("score"),
                            rs.getString("title"), rs.getString("resolution")));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        return matches;
    }
}
