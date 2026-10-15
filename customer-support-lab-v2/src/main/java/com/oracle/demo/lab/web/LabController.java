// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.web;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.Arrays;
import java.util.List;

/** Read-only snapshots for the local lab UI; these counts are not telemetry metrics. */
@RestController
public class LabController {
    private final JdbcClient jdbc;
    private final Environment environment;

    public LabController(JdbcClient jdbc, Environment environment) {
        this.jdbc = jdbc;
        this.environment = environment;
    }

    @GetMapping("/api/lab")
    public Snapshot snapshot() {
        String[] profiles = environment.getActiveProfiles();
        if (profiles.length == 0) {
            profiles = environment.getDefaultProfiles();
        }
        var tables = jdbc.sql("""
                select 'support_ticket' name, count(*) row_count from support_ticket
                union all select 'support_policy', count(*) from support_policy
                union all select 'ticket_assistance', count(*) from ticket_assistance
                union all select 'related_ticket', count(*) from related_ticket
                union all select 'ticket_policy_match', count(*) from ticket_policy_match
                union all select 'ticket_event_processed', count(*) from ticket_event_processed
                union all select 'failed_ticket_event', count(*) from failed_ticket_event
                union all select 'ticket_approval_history', count(*) from ticket_approval_history
                """).query((rs, n) -> new TableCount(rs.getString("name"), rs.getLong("row_count"))).list();
        var policies = jdbc.sql("""
                select policy_id, title, body,
                       case when embedding is null then 0 else 1 end indexed
                from support_policy order by policy_id
                """).query((rs, n) -> new Policy(rs.getString("policy_id"), rs.getString("title"),
                        rs.getString("body"), rs.getBoolean("indexed"))).list();
        var reviews = jdbc.sql("""
                select a.ticket_id, a.generated_at, r.decision, from_tz(r.decided_at, 'UTC') decided_at
                from ticket_assistance a
                left join (
                    select ticket_id, decision, decided_at,
                           row_number() over (partition by ticket_id order by decided_at desc, action_id desc) rn
                    from ticket_approval_history
                ) r on r.ticket_id = a.ticket_id and r.rn = 1
                order by a.ticket_id
                """).query((rs, n) -> {
                    OffsetDateTime decidedAt = rs.getObject("decided_at", OffsetDateTime.class);
                    return new ReviewState(rs.getLong("ticket_id"),
                            rs.getObject("generated_at", OffsetDateTime.class).toInstant(),
                            rs.getString("decision"), decidedAt == null ? null : decidedAt.toInstant());
                }).list();
        return new Snapshot(Instant.now(), Arrays.asList(profiles),
                environment.acceptsProfiles(Profiles.of("events & ai & blockchain")),
                environment.getProperty("app.ai.chat-model-id", "cohere.command-a-03-2025"),
                environment.getProperty("spring.ai.oci.genai.embedding.model", "cohere.embed-v4.0"),
                environment.getProperty("okafka.topic.tickets", "ticket_event"), tables, policies, reviews);
    }

    public record Snapshot(Instant capturedAt, List<String> profiles, boolean reviewEnabled,
                           String chatModel, String embeddingModel, String topic,
                           List<TableCount> tables, List<Policy> policies, List<ReviewState> reviewStates) {}
    public record TableCount(String name, long rows) {}
    public record Policy(String id, String title, String body, boolean indexed) {}
    public record ReviewState(long ticketId, Instant generatedAt, String decision, Instant decidedAt) {}
}
