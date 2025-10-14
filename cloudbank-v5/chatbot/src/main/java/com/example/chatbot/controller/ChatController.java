// Copyright (c) 2024, 2025, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.chatbot.controller;


import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.api.OllamaModel;
import org.springframework.ai.ollama.api.OllamaOptions;
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
    public String chat(@RequestBody String question) {
        
        ChatResponse response = chatModel.call(
            new Prompt(question,
                OllamaOptions.builder()
                .model(OllamaModel.LLAMA3)
                .temperature(0.4d)
                .build()
        ));

        return response.getResult().getOutput().getText();
       
    }
    
}