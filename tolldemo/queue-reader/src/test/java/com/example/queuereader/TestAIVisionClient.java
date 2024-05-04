package com.example.queuereader;

import org.junit.jupiter.api.Test;

import com.example.queuereader.client.AIVisionClient;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class TestAIVisionClient {

    @Test
    public void testImageAnalyze() {
        AIVisionClient client = new AIVisionClient();

        String response = client.analyzeImage("suv/PHOTO_96.jpg");
        log.info(response.toString());
    }

}
