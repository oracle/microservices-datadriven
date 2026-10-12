// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Component
@Profile("ai")
public class TicketAssistanceStore {
    private final JdbcClient jdbcClient;

    public TicketAssistanceStore(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    /** Persists the first successful enrichment on the consumer's TxEventQ connection. */
    public void save(Connection connection, long ticketId, String summary, String modelId,
                     String promptVersion, List<RelatedTicket> relatedTickets,
                     List<PolicyMatch> policies) {
        try (PreparedStatement assistance = connection.prepareStatement("""
                insert into ticket_assistance (ticket_id, summary, summary_model, prompt_version)
                values (?, ?, ?, ?)
                """);
             PreparedStatement addRelated = connection.prepareStatement("""
                     insert into related_ticket (ticket_id, related, score) values (?, ?, ?)
                     """);
             PreparedStatement addPolicy = connection.prepareStatement("""
                     insert into ticket_policy_match (ticket_id, policy_id, score) values (?, ?, ?)
                     """)) {
            assistance.setLong(1, ticketId);
            assistance.setString(2, summary);
            assistance.setString(3, modelId);
            assistance.setString(4, promptVersion);
            assistance.executeUpdate();

            for (RelatedTicket related : relatedTickets) {
                addRelated.setLong(1, ticketId);
                addRelated.setLong(2, related.relatedTicketId());
                addRelated.setDouble(3, related.score());
                addRelated.addBatch();
            }
            if (!relatedTickets.isEmpty()) {
                addRelated.executeBatch();
            }
            for (PolicyMatch policy : policies) {
                addPolicy.setLong(1, ticketId);
                addPolicy.setString(2, policy.policyId());
                addPolicy.setDouble(3, policy.score());
                addPolicy.addBatch();
            }
            if (!policies.isEmpty()) {
                addPolicy.executeBatch();
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not persist ticket assistance", e);
        }
    }

    public Optional<TicketAssistance> findByTicketId(long ticketId) {
        Optional<SummaryRow> summary = jdbcClient.sql("""
                select ticket_id, summary, summary_model, prompt_version, generated_at
                from ticket_assistance where ticket_id = ?
                """)
                .param(ticketId)
                .query((rs, rowNum) -> {
                    Timestamp generatedAt = rs.getTimestamp("generated_at");
                    return new SummaryRow(rs.getLong("ticket_id"), rs.getString("summary"),
                            rs.getString("summary_model"), rs.getString("prompt_version"),
                            generatedAt.toInstant());
                })
                .optional();
        return summary.map(row -> new TicketAssistance(row.ticketId(), row.summary(),
                row.modelId(), row.promptVersion(), row.generatedAt(),
                findSimilarTickets(ticketId), findPolicies(ticketId)));
    }

    private List<RelatedTicket> findSimilarTickets(long ticketId) {
        return jdbcClient.sql("""
                select related, score from related_ticket
                where ticket_id = ? order by score desc
                """)
                .param(ticketId)
                .query((rs, rowNum) -> new RelatedTicket(rs.getLong("related"), rs.getDouble("score")))
                .list();
    }

    private List<PolicyMatch> findPolicies(long ticketId) {
        return jdbcClient.sql("""
                select m.policy_id, p.title, m.score
                from ticket_policy_match m join support_policy p on p.policy_id = m.policy_id
                where m.ticket_id = ? order by m.score desc
                """)
                .param(ticketId)
                .query((rs, rowNum) -> new PolicyMatch(rs.getString("policy_id"),
                        rs.getString("title"), rs.getDouble("score")))
                .list();
    }

    private record SummaryRow(long ticketId, String summary, String modelId,
                              String promptVersion, Instant generatedAt) {
    }
}
