package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.AIVisionClient;
import com.oracle.bmc.aivision.responses.AnalyzeImageResponse;

@Service
public class AIVisionService {
    
    private AIVisionClient client; 

    AIVisionService(AIVisionClient client) {
        this.client = client;
    }

    public AnalyzeImageResponse analyzeImage(String imageUrl) {
        return client.analyzeImage(imageUrl);
    }

}
