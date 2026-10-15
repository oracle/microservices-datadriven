// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.processing;

import com.oracle.demo.lab.ai.PolicyMatch;
import com.oracle.demo.lab.ai.PolicyVectorStore;
import com.oracle.demo.lab.ai.TicketAssistanceStore;
import com.oracle.demo.lab.ai.TicketSummarizer;
import com.oracle.demo.lab.ai.TicketVectorStore;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.model.RelatedTicket;
import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.model.TicketStatus;
import com.oracle.demo.lab.persistence.TicketStore;

import com.oracle.demo.lab.processing.GenAIEventProcessor;
import org.junit.jupiter.api.Test;
import org.springframework.ai.embedding.EmbeddingModel;

import java.sql.Connection;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

class GenAIEventProcessorTest {
    @Test
    void feedbackRevisesPreviousSummaryAndRefreshesEmbeddingAndMatches() {
        Connection connection = mock(Connection.class);
        TicketVectorStore ticketVectors = mock(TicketVectorStore.class);
        EmbeddingModel embeddingModel = mock(EmbeddingModel.class);
        TicketStore ticketStore = mock(TicketStore.class);
        PolicyVectorStore policyVectors = mock(PolicyVectorStore.class);
        TicketSummarizer summarizer = mock(TicketSummarizer.class);
        TicketAssistanceStore assistanceStore = mock(TicketAssistanceStore.class);
        TicketTelemetry telemetry = new TicketTelemetry(new io.micrometer.core.instrument.simple.SimpleMeterRegistry(),
                io.micrometer.observation.ObservationRegistry.create());
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        ticket.setTitle("Sign-in failure");
        ticket.setDescription("Cannot access account");
        ticket.setReviewFeedback("The account belongs to the test tenant.");
        float[] embedding = new float[1536];
        when(embeddingModel.embed(any(String.class))).thenReturn(embedding);
        when(ticketVectors.search(0.2, embedding, 42L, connection)).thenReturn(List.of());
        when(policyVectors.search(connection, embedding)).thenReturn(List.of());
        when(assistanceStore.findSummary(connection, 42L)).thenReturn("Production account cannot sign in.");
        when(summarizer.summarize(ticket, "Production account cannot sign in."))
                .thenReturn("Test tenant account cannot sign in.");
        when(summarizer.modelId()).thenReturn("chat");
        GenAIEventProcessor processor = new GenAIEventProcessor(ticketVectors, embeddingModel,
                ticketStore, policyVectors, summarizer, assistanceStore, telemetry);

        processor.processRecord(connection,
                TicketWorkEvent.feedbackSubmitted(42L, java.util.UUID.randomUUID()), ticket);

        verify(embeddingModel).embed("Sign-in failure\nCannot access account\nReviewer feedback: The account belongs to the test tenant.");
        var calls = inOrder(assistanceStore, ticketStore);
        calls.verify(assistanceStore).findSummary(connection, 42L);
        calls.verify(ticketStore).saveEnrichment(connection, 42L, embedding);
        calls.verify(assistanceStore).save(connection, 42L, "Test tenant account cannot sign in.",
                "chat", TicketSummarizer.PROMPT_VERSION, List.of(), List.of());
        assertEquals(TicketStatus.ENRICHED, ticket.getWorkflowStatus());
    }

    @Test
    void persistsSummaryAndPolicyMatchesWithTicketOnConsumerConnection() {
        Connection connection = mock(Connection.class);
        TicketVectorStore ticketVectors = mock(TicketVectorStore.class);
        EmbeddingModel embeddingModel = mock(EmbeddingModel.class);
        TicketStore ticketStore = mock(TicketStore.class);
        PolicyVectorStore policyVectors = mock(PolicyVectorStore.class);
        TicketSummarizer summarizer = mock(TicketSummarizer.class);
        TicketAssistanceStore assistanceStore = mock(TicketAssistanceStore.class);
        TicketTelemetry telemetry = new TicketTelemetry(new io.micrometer.core.instrument.simple.SimpleMeterRegistry(),
                io.micrometer.observation.ObservationRegistry.create());
        SupportTicket ticket = new SupportTicket();
        ticket.setId(42L);
        ticket.setTitle("Lost authenticator");
        ticket.setDescription("Cannot sign in");
        float[] embedding = new float[1536];
        RelatedTicket similar = new RelatedTicket(7L, 0.82);
        PolicyMatch policy = new PolicyMatch("MFA_RECOVERY", "MFA recovery", 0.9);
        when(embeddingModel.embed(any(String.class))).thenReturn(embedding);
        when(ticketVectors.search(0.2, embedding, 42L, connection)).thenReturn(List.of(similar));
        when(policyVectors.search(connection, embedding)).thenReturn(List.of(policy));
        when(summarizer.summarize(ticket)).thenReturn("User lost MFA access.");
        when(summarizer.modelId()).thenReturn("demo-chat-model");
        GenAIEventProcessor processor = new GenAIEventProcessor(ticketVectors, embeddingModel,
                ticketStore, policyVectors, summarizer, assistanceStore, telemetry);

        processor.processRecord(connection, TicketWorkEvent.submitted(42L, null), ticket);

        assertEquals(TicketStatus.ENRICHED, ticket.getWorkflowStatus());
        var calls = inOrder(policyVectors, ticketStore, assistanceStore);
        calls.verify(policyVectors).search(connection, embedding);
        calls.verify(ticketStore).saveEnrichment(connection, 42L, embedding);
        calls.verify(assistanceStore).save(eq(connection), eq(42L), eq("User lost MFA access."),
                eq("demo-chat-model"), eq(TicketSummarizer.PROMPT_VERSION),
                eq(List.of(similar)), eq(List.of(policy)));
    }
}
