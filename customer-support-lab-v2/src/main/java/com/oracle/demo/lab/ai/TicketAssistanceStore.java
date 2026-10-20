// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
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
public class TicketAssistanceStore {
    private final JdbcClient jdbcClient;

    public TicketAssistanceStore(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    /** Replaces the current assistance and matches on the consumer's TxEventQ connection. */
    public void save(Connection connection, long ticketId, String summary, String suggestedResolution, String modelId,
                     String promptVersion, List<RelatedTicket> relatedTickets,
                     List<PolicyMatch> policies) {
        try (PreparedStatement assistance = connection.prepareStatement("""
                merge into ticket_assistance a
                using (select ? ticket_id, ? summary, ? suggested_resolution, ? summary_model, ? prompt_version from dual) s
                on (a.ticket_id = s.ticket_id)
                when matched then update set a.summary = s.summary, a.suggested_resolution = s.suggested_resolution,
                    a.summary_model = s.summary_model,
                    a.prompt_version = s.prompt_version, a.generated_at = systimestamp
                when not matched then insert (ticket_id, summary, suggested_resolution, summary_model, prompt_version)
                    values (s.ticket_id, s.summary, s.suggested_resolution, s.summary_model, s.prompt_version)
                """);
             PreparedStatement clearRelated = connection.prepareStatement(
                     "delete from related_ticket where ticket_id = ?");
             PreparedStatement clearPolicies = connection.prepareStatement(
                     "delete from ticket_policy_match where ticket_id = ?");
             PreparedStatement addRelated = connection.prepareStatement("""
                     insert into related_ticket (ticket_id, related, score) values (?, ?, ?)
                     """);
             PreparedStatement addPolicy = connection.prepareStatement("""
                     insert into ticket_policy_match (ticket_id, policy_id, score) values (?, ?, ?)
                     """)) {
            assistance.setLong(1, ticketId);
            assistance.setString(2, summary);
            assistance.setString(3, suggestedResolution);
            assistance.setString(4, modelId);
            assistance.setString(5, promptVersion);
            assistance.executeUpdate();
            clearRelated.setLong(1, ticketId);
            clearRelated.executeUpdate();
            clearPolicies.setLong(1, ticketId);
            clearPolicies.executeUpdate();

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

    public String findPreviousAssistance(Connection connection, long ticketId) {
        try (PreparedStatement statement = connection.prepareStatement(
                "select summary, suggested_resolution from ticket_assistance where ticket_id = ?")) {
            statement.setLong(1, ticketId);
            try (var rows = statement.executeQuery()) {
                if (!rows.next()) {
                    throw new IllegalStateException("Regeneration requires saved assistance");
                }
                return TicketAssistance.reviewText(rows.getString("summary"), rows.getString("suggested_resolution"));
            }
        } catch (SQLException failure) {
            throw new IllegalStateException("Could not read the previous assistance", failure);
        }
    }

    public Optional<TicketAssistance> findByTicketId(long ticketId) {
        Optional<SummaryRow> summary = jdbcClient.sql("""
                select ticket_id, summary, suggested_resolution, summary_model, prompt_version, generated_at
                from ticket_assistance where ticket_id = ?
                """)
                .param(ticketId)
                .query((rs, rowNum) -> {
                    Timestamp generatedAt = rs.getTimestamp("generated_at");
                    return new SummaryRow(rs.getLong("ticket_id"), rs.getString("summary"), rs.getString("suggested_resolution"),
                            rs.getString("summary_model"), rs.getString("prompt_version"),
                            generatedAt.toInstant());
                })
                .optional();
        return summary.map(row -> new TicketAssistance(row.ticketId(), row.summary(), row.suggestedResolution(),
                row.modelId(), row.promptVersion(), row.generatedAt(),
                findSimilarTickets(ticketId), findPolicies(ticketId)));
    }

    private List<RelatedTicket> findSimilarTickets(long ticketId) {
        return jdbcClient.sql("""
                select r.related, r.score, t.title, t.resolution from related_ticket r
                join support_ticket t on t.id = r.related
                where r.ticket_id = ? order by r.score desc
                """)
                .param(ticketId)
                .query((rs, rowNum) -> new RelatedTicket(rs.getLong("related"), rs.getDouble("score"),
                        rs.getString("title"), rs.getString("resolution")))
                .list();
    }

    private List<PolicyMatch> findPolicies(long ticketId) {
        return jdbcClient.sql("""
                select m.policy_id, p.title, m.score, p.body
                from ticket_policy_match m join support_policy p on p.policy_id = m.policy_id
                where m.ticket_id = ? order by m.score desc
                """)
                .param(ticketId)
                .query((rs, rowNum) -> new PolicyMatch(rs.getString("policy_id"),
                        rs.getString("title"), rs.getDouble("score"), rs.getString("body")))
                .list();
    }

    private record SummaryRow(long ticketId, String summary, String suggestedResolution, String modelId,
                              String promptVersion, Instant generatedAt) {
    }
}
