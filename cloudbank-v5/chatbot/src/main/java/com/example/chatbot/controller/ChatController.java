// Copyright (c) 2024, 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.chatbot.controller;

import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/chat")
public class ChatController {

    final ChatModel chatModel;

    public ChatController(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    /**
     * Returns a chatresponse on a provided question.
     * @param question Question asked.
     * @return Chatresponse content.
     */
    @PostMapping
    public ResponseEntity<String> chat(@RequestBody String question) {
        ChatResponse response = chatModel.call(new Prompt(question));
        Generation result = response.getResult();
        if (result == null || result.getOutput() == null) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Chat service is temporarily unavailable.");
        }
        return ResponseEntity.ok(result.getOutput().getText());
    }

}
