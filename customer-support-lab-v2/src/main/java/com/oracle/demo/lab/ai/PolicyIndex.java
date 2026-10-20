// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;

/** Indexes policies and recorded reference resolutions before the consumer starts. */
@Component
public class PolicyIndex implements ApplicationRunner {
    private static final int EMBEDDING_DIMENSIONS = 1536;

    private final JdbcClient jdbcClient;
    private final DataSource dataSource;
    private final EmbeddingModel embeddingModel;

    public PolicyIndex(JdbcClient jdbcClient, DataSource dataSource, EmbeddingModel embeddingModel) {
        this.jdbcClient = jdbcClient;
        this.dataSource = dataSource;
        this.embeddingModel = embeddingModel;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<Reference> missing = jdbcClient.sql("""
                select policy_id, title, body from support_policy
                where embedding is null
                order by policy_id
                """)
                .query((rs, rowNum) -> new Reference(rs.getString("policy_id"),
                        rs.getString("title") + "\n" + rs.getString("body")))
                .list();
        index(missing, "update support_policy set embedding = ? where policy_id = ?");
        List<Reference> resolved = jdbcClient.sql("""
                select id, title, description, resolution from support_ticket
                where resolution is not null and embedding is null order by id
                """)
                .query((rs, rowNum) -> new Reference(rs.getLong("id"),
                        rs.getString("title") + "\n" + rs.getString("description")
                                + "\nRecorded resolution: " + rs.getString("resolution")))
                .list();
        index(resolved, "update support_ticket set embedding = ? where id = ?");
    }

    private void index(List<Reference> missing, String updateSql) {
        if (missing.isEmpty()) {
            return;
        }

        List<String> texts = missing.stream().map(Reference::text).toList();
        List<float[]> embeddings = embeddingModel.embed(texts);
        if (embeddings.size() != missing.size()) {
            throw new IllegalStateException("Reference embedding count did not match the corpus");
        }
        for (float[] embedding : embeddings) {
            if (embedding == null || embedding.length != EMBEDDING_DIMENSIONS) {
                throw new IllegalStateException("Reference embeddings must have 1536 dimensions");
            }
        }

        try (Connection connection = dataSource.getConnection()) {
            boolean autoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                for (int i = 0; i < missing.size(); i++) {
                    statement.setObject(1, VECTOR.ofFloat32Values(embeddings.get(i)),
                            OracleType.VECTOR.getVendorTypeNumber());
                    statement.setObject(2, missing.get(i).id());
                    statement.addBatch();
                }
                statement.executeBatch();
                connection.commit();
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(autoCommit);
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not index reference data", e);
        }
    }

    private record Reference(Object id, String text) {
    }
}
