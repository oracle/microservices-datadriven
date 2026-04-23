// Copyright (c) 2024, 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.chatbot;

import java.util.List;

import com.example.chatbot.controller.ChatController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatbotApplicationTest {

    @Mock
    private ChatModel chatModel;

    private ChatController controller;

    @BeforeEach
    void setUp() {
        controller = new ChatController(chatModel);
    }

    @Test
    @DisplayName("Should return 200 with model response text on success")
    void chat_returnsModelResponseText() {
        AssistantMessage message = new AssistantMessage("Paris");
        Generation generation = new Generation(message);
        ChatResponse chatResponse = new ChatResponse(List.of(generation));
        when(chatModel.call(any(Prompt.class))).thenReturn(chatResponse);

        ResponseEntity<String> response = controller.chat("What is the capital of France?");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("Paris", response.getBody());
    }

    @Test
    @DisplayName("Should return 503 when model returns no results")
    void chat_nullResult_returns503() {
        ChatResponse chatResponse = new ChatResponse(List.of());
        when(chatModel.call(any(Prompt.class))).thenReturn(chatResponse);

        ResponseEntity<String> response = controller.chat("Hello");

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
    }

    @Test
    @DisplayName("Should return 503 when generation output is null")
    void chat_nullOutput_returns503() {
        Generation generation = mock(Generation.class);
        when(generation.getOutput()).thenReturn(null);
        ChatResponse chatResponse = new ChatResponse(List.of(generation));
        when(chatModel.call(any(Prompt.class))).thenReturn(chatResponse);

        ResponseEntity<String> response = controller.chat("Hello");

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
    }

    @Test
    @DisplayName("Should pass the question to the model unchanged")
    void chat_promptPassedThroughUnchanged() {
        String question = "What is 2+2?";
        AssistantMessage message = new AssistantMessage("4");
        ChatResponse chatResponse = new ChatResponse(List.of(new Generation(message)));
        when(chatModel.call(any(Prompt.class))).thenReturn(chatResponse);

        controller.chat(question);

        ArgumentCaptor<Prompt> captor = ArgumentCaptor.forClass(Prompt.class);
        verify(chatModel).call(captor.capture());
        assertEquals(question, captor.getValue().getContents());
    }

    @Test
    @DisplayName("Should propagate exception when model throws")
    void chat_modelThrows_propagatesException() {
        when(chatModel.call(any(Prompt.class)))
                .thenThrow(new RuntimeException("Ollama connection refused"));

        assertThrows(RuntimeException.class, () -> controller.chat("Hello"));
    }

}
