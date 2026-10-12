// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import com.oracle.demo.lab.model.TicketStatus;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.util.EnumMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/** Refreshes bounded, low-cardinality database gauges outside the scrape path. */
@Configuration
@EnableScheduling
@Profile("events & observability")
public class TicketStateMetrics {
    private static final Logger log = LoggerFactory.getLogger(TicketStateMetrics.class);
    private final JdbcClient jdbc;
    private final Map<TicketStatus, AtomicLong> states = new EnumMap<>(TicketStatus.class);
    private final AtomicLong failedWorklist = new AtomicLong();

    public TicketStateMetrics(JdbcClient jdbc, MeterRegistry meters) {
        this.jdbc = jdbc;
        for (TicketStatus state : TicketStatus.values()) {
            AtomicLong count = new AtomicLong();
            states.put(state, count);
            meters.gauge("support.ticket.state", java.util.List.of(Tag.of("state", state.name())), count);
        }
        meters.gauge("support.ticket.failed.worklist", failedWorklist);
    }

    @Scheduled(fixedDelayString = "${app.observability.state-refresh-ms:10000}")
    public void refresh() {
        try {
            Map<TicketStatus, Long> counts = new EnumMap<>(TicketStatus.class);
            jdbc.sql("select workflow_status, count(*) as ticket_count from support_ticket group by workflow_status")
                    .query((rs, row) -> {
                        counts.put(TicketStatus.valueOf(rs.getString("workflow_status")), rs.getLong("ticket_count"));
                        return null;
                    }).list();
            long failures = jdbc.sql("select count(*) from failed_ticket_event where status = 'FAILED'")
                    .query(Long.class).single();
            states.forEach((state, count) -> count.set(counts.getOrDefault(state, 0L)));
            failedWorklist.set(failures);
        } catch (RuntimeException error) {
            log.warn("Could not refresh ticket state gauges ({})", error.getClass().getSimpleName());
        }
    }
}
