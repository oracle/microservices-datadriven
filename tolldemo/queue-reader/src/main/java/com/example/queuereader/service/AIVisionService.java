package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.AIVisionClient;

@Service
public class AIVisionService {
    
    private AIVisionClient client; 

    AIVisionService(AIVisionClient client) {
        this.client = client;
    }

    public String analyzeImage(String imageUrl) {
        return client.analyzeImage(imageUrl);
    }

}
