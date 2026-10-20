// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.RelatedTicket;
import com.oracle.demo.lab.model.SupportTicket;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class TicketSummarizerTest {
    private final PolicyMatch policy = new PolicyMatch("MFA_RECOVERY", "MFA recovery", 0.9,
            "Verify identity before replacing a factor.");
    private final RelatedTicket resolved = new RelatedTicket(7, 0.9, "Lost phone",
            "Verified identity and replaced the factor.");

    @Test
    void generatesBothOutputsInOneCallUsingPolicyBodiesAndRecordedResolutions() {
        ChatModel model = mock(ChatModel.class);
        when(model.call(any(Prompt.class))).thenAnswer(call -> {
            Prompt prompt = call.getArgument(0);
            String context = prompt.getUserMessage().getText();
            assertTrue(context.contains("[Policy MFA_RECOVERY]"));
            assertTrue(context.contains(policy.body()));
            assertTrue(context.contains("[Ticket #7]"));
            assertTrue(context.contains(resolved.resolution()));
            assertFalse(context.contains("Unresolved case"));
            assertTrue(prompt.getSystemMessage().getText().contains("untrusted data"));
            assertTrue(prompt.getSystemMessage().getText().contains("Policies take precedence"));
            return response("""
                    {"summary":"  User lost MFA access.  ",
                     "suggestedResolution":"Verify identity [Policy MFA_RECOVERY], then review the recovery steps [Ticket #7]."}
                    """);
        });
        var generator = new TicketSummarizer(model, "demo-chat-model");
        var draft = generator.generate(ticket(), List.of(resolved,
                new RelatedTicket(8, 0.8, "Unresolved case", null)), List.of(policy), null);

        assertEquals("User lost MFA access.", draft.summary());
        assertTrue(draft.suggestedResolution().contains("[Ticket #7]"));
        assertEquals("demo-chat-model", generator.modelId());
        verify(model, times(1)).call(any(Prompt.class));
    }

    @Test
    void regenerationIncludesPreviousAssistanceAndFeedback() {
        ChatModel model = mock(ChatModel.class);
        when(model.call(any(Prompt.class))).thenAnswer(call -> {
            Prompt prompt = call.getArgument(0);
            String context = prompt.getUserMessage().getText();
            assertTrue(context.contains("Description: Cannot sign in"));
            assertTrue(context.contains("Previous assistance: Old summary and old suggested resolution."));
            assertTrue(context.contains("Reviewer feedback (oldest to newest): This is a test tenant."));
            assertTrue(prompt.getSystemMessage().getText().contains("revise both outputs"));
            return response("""
                    {"summary":"Test tenant sign-in failed.",
                     "suggestedResolution":"Verify the test-tenant identity [Policy MFA_RECOVERY]."}
                    """);
        });
        SupportTicket ticket = ticket();
        ticket.setReviewFeedback("This is a test tenant.");
        var draft = new TicketSummarizer(model, "chat").generate(ticket, List.of(), List.of(policy),
                "Old summary and old suggested resolution.");
        assertEquals("Test tenant sign-in failed.", draft.summary());
    }

    @Test
    void rejectsEmptyMalformedAndIncompleteOutputs() {
        for (String text : List.of(" ", "Not JSON", "{}", "{\"summary\":\"A problem\"}")) {
            ChatModel model = mock(ChatModel.class);
            when(model.call(any(Prompt.class))).thenReturn(response(text));
            assertThrows(RuntimeException.class,
                    () -> new TicketSummarizer(model, "chat").generate(ticket(), List.of(), List.of(), null));
        }
    }

    @Test
    void rejectsCitationsToSourcesThatWereNotRetrieved() {
        ChatModel model = mock(ChatModel.class);
        when(model.call(any(Prompt.class))).thenReturn(response("""
                {"summary":"Lost MFA access.","suggestedResolution":"Follow the previous fix [Ticket #99]."}
                """));
        assertThrows(IllegalStateException.class, () -> new TicketSummarizer(model, "chat")
                .generate(ticket(), List.of(resolved), List.of(policy), null));
    }

    @Test
    void permitsAnExplicitInsufficientEvidenceResponseWhenThereAreNoSources() {
        ChatModel model = mock(ChatModel.class);
        when(model.call(any(Prompt.class))).thenReturn(response("""
                {"summary":"Lost MFA access.",
                 "suggestedResolution":"Insufficient supporting evidence. Ask which account and tenant are affected."}
                """));
        assertTrue(new TicketSummarizer(model, "chat").generate(ticket(), List.of(), List.of(), null)
                .suggestedResolution().startsWith("Insufficient"));
    }

    private static SupportTicket ticket() {
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Lost authenticator");
        ticket.setDescription("Cannot sign in");
        return ticket;
    }

    private static ChatResponse response(String text) {
        return new ChatResponse(List.of(new Generation(new AssistantMessage(text))));
    }
}
