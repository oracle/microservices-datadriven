// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ai.vectorstore.TicketVectorStore;
import com.oracle.demo.lab.ai.PolicyIndex;
import com.oracle.demo.lab.ai.PolicyMatch;
import com.oracle.demo.lab.ai.PolicyVectorStore;
import com.oracle.demo.lab.ai.TicketAssistanceStore;
import com.oracle.demo.lab.ai.TicketSummarizer;
import com.oracle.demo.lab.ticket.RelatedTicket;
import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketStore;
import com.oracle.demo.lab.ticket.TicketStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.util.List;

@Component
@Profile("ai")
public class GenAIEventProcessor implements TicketEventProcessor {
    private static final Logger log = LoggerFactory.getLogger(GenAIEventProcessor.class);

    private final TicketVectorStore ticketVectorStore;
    private final EmbeddingModel embeddingModel;
    private final TicketStore ticketStore;
    private final PolicyIndex policyIndex;
    private final PolicyVectorStore policyVectorStore;
    private final TicketSummarizer ticketSummarizer;
    private final TicketAssistanceStore assistanceStore;
    private final TicketTelemetry telemetry;

    public GenAIEventProcessor(TicketVectorStore ticketVectorStore,
                               EmbeddingModel embeddingModel, TicketStore ticketStore,
                               PolicyIndex policyIndex, PolicyVectorStore policyVectorStore,
                               TicketSummarizer ticketSummarizer, TicketAssistanceStore assistanceStore,
                               TicketTelemetry telemetry) {
        this.ticketVectorStore = ticketVectorStore;
        this.embeddingModel = embeddingModel;
        this.ticketStore = ticketStore;
        this.policyIndex = policyIndex;
        this.policyVectorStore = policyVectorStore;
        this.ticketSummarizer = ticketSummarizer;
        this.assistanceStore = assistanceStore;
        this.telemetry = telemetry;
    }

    @Override
    public void processRecord(Connection conn, TicketWorkEvent event, SupportTicket ticket) {
        log.info("Enriching ticket eventId={} correlationId={} ticketId={}",
                event.getEventId(), event.getCorrelationId(), ticket.getId());
        float[] vector = telemetry.step("embedding",
                () -> embeddingModel.embed(ticket.getTitle() + "\n" + ticket.getDescription()));
        List<RelatedTicket> relatedTickets = telemetry.step("related_tickets",
                () -> ticketVectorStore.search(0.2, vector, ticket.getId(), conn));
        telemetry.matches("ticket", relatedTickets.size());
        List<PolicyMatch> policies = telemetry.step("policies", () -> {
            policyIndex.ensureIndexed();
            return policyVectorStore.search(conn, vector);
        });
        telemetry.matches("policy", policies.size());
        String summary = telemetry.step("summary", () -> ticketSummarizer.summarize(ticket));
        ticket.setWorkflowStatus(TicketStatus.ENRICHED);

        log.info("Enriched ticket eventId={} ticketId={} relatedTicketCount={} policyCount={} status={}",
                event.getEventId(), ticket.getId(), relatedTickets.size(), policies.size(), ticket.getWorkflowStatus());
        telemetry.step("persistence", () -> {
            ticketStore.saveEnrichment(conn, ticket.getId(), vector);
            assistanceStore.save(conn, ticket.getId(), summary, ticketSummarizer.modelId(),
                    TicketSummarizer.PROMPT_VERSION, relatedTickets, policies);
            return null;
        });
    }
}
