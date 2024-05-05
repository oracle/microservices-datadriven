package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.AIVisionClient;

import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;

@Service
public class AIVisionService {
    
    private AIVisionClient client; 

    AIVisionService(AIVisionClient client, MeterRegistry registry) {
        this.client = client;
        registry.timer("ai.vision", Tags.empty());
    }

    @Timed(value = "ai.vision")
    public String analyzeImage(String imageUrl) {
        return client.analyzeImage(imageUrl);
    }

}
