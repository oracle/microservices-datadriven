// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import oracle.jdbc.OracleType;
import oracle.sql.VECTOR;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;

/** Embeds the small seeded corpus once per embedding model, outside ticket transactions. */
@Component
@Profile("ai")
public class PolicyIndex {
    private static final int EMBEDDING_DIMENSIONS = 1536;

    private final JdbcClient jdbcClient;
    private final DataSource dataSource;
    private final EmbeddingModel embeddingModel;
    private final String modelId;

    public PolicyIndex(JdbcClient jdbcClient, DataSource dataSource, EmbeddingModel embeddingModel,
                       @Value("${app.ai.embedding-model-id}") String modelId) {
        this.jdbcClient = jdbcClient;
        this.dataSource = dataSource;
        this.embeddingModel = embeddingModel;
        this.modelId = modelId;
    }

    public synchronized void ensureIndexed() {
        List<Policy> missing = jdbcClient.sql("""
                select policy_id, title, body from support_policy
                where embedding is null or embedding_model is null or embedding_model <> ?
                order by policy_id
                """)
                .param(modelId)
                .query((rs, rowNum) -> new Policy(
                        rs.getString("policy_id"), rs.getString("title"), rs.getString("body")))
                .list();
        if (missing.isEmpty()) {
            return;
        }

        List<String> texts = missing.stream().map(policy -> policy.title() + "\n" + policy.body()).toList();
        List<float[]> embeddings = embeddingModel.embed(texts);
        if (embeddings.size() != missing.size()) {
            throw new IllegalStateException("Policy embedding count did not match the policy corpus");
        }
        for (float[] embedding : embeddings) {
            if (embedding == null || embedding.length != EMBEDDING_DIMENSIONS) {
                throw new IllegalStateException("Policy embeddings must have 1536 dimensions");
            }
        }

        try (Connection connection = dataSource.getConnection()) {
            boolean autoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement("""
                    update support_policy set embedding = ?, embedding_model = ? where policy_id = ?
                    """)) {
                for (int i = 0; i < missing.size(); i++) {
                    statement.setObject(1, VECTOR.ofFloat32Values(embeddings.get(i)),
                            OracleType.VECTOR.getVendorTypeNumber());
                    statement.setString(2, modelId);
                    statement.setString(3, missing.get(i).id());
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
            throw new IllegalStateException("Could not index support policies", e);
        }
    }

    private record Policy(String id, String title, String body) {
    }
}
