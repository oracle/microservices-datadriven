// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.model.SupportTicket;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TicketSummarizerTest {
    @Test
    void requestsShortSummaryAndKeepsModelMetadata() {
        ChatModel chatModel = mock(ChatModel.class);
        when(chatModel.call(any(Prompt.class))).thenAnswer(invocation -> {
            Prompt prompt = invocation.getArgument(0);
            assertTrue(prompt.getSystemMessage().getText().contains("untrusted data"));
            assertTrue(prompt.getUserMessage().getText().contains("Lost authenticator"));
            return new ChatResponse(List.of(new Generation(new AssistantMessage("  User lost MFA access.  "))));
        });
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Lost authenticator");
        ticket.setDescription("Cannot sign in");
        TicketSummarizer summarizer = new TicketSummarizer(chatModel, "demo-chat-model");

        assertEquals("User lost MFA access.", summarizer.summarize(ticket));
        assertEquals("demo-chat-model", summarizer.modelId());
    }

    @Test
    void rejectsEmptyModelOutput() {
        ChatModel chatModel = mock(ChatModel.class);
        when(chatModel.call(any(Prompt.class))).thenReturn(
                new ChatResponse(List.of(new Generation(new AssistantMessage("  ")))));
        SupportTicket ticket = new SupportTicket();
        ticket.setTitle("Problem");
        ticket.setDescription("Details");

        assertThrows(IllegalStateException.class,
                () -> new TicketSummarizer(chatModel, "demo-chat-model").summarize(ticket));
    }
}
