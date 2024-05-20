package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.AIVisionClient;

import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.Timer;
import io.micrometer.prometheus.PrometheusMeterRegistry;

@Service
public class AIVisionService {
    
    private AIVisionClient client; 
    private Timer timer;

    AIVisionService(AIVisionClient client, PrometheusMeterRegistry registry) {
        this.client = client;
        timer = registry.timer("ai.vision", Tags.empty());
    }

    public String analyzeImage(String imageUrl) {
        Timer.Sample sample = Timer.start();
        String response = client.analyzeImage(imageUrl);
        timer.record(() -> sample.stop(timer) / 1_000_000);
        return response;
    }

}
