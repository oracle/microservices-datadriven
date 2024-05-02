// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.controller;

import com.example.queuereader.service.AIVisionService;
import com.example.queuereader.service.JournalService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import lombok.extern.slf4j.Slf4j;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class TollReaderReceiver {

    ObjectMapper objectMapper = new ObjectMapper();

    private JournalService journalService;
    private AIVisionService aiVisionService;

    public TollReaderReceiver(JournalService journalService, AIVisionService aiVisionService) {
        this.journalService = journalService;
        this.aiVisionService = aiVisionService;
    }

    @JmsListener(destination = "TollGate")
    public void receiveTollData(String tollData) {
        log.info("Received message {}", tollData);
        try {
            JsonNode tollDataJson = objectMapper.readTree(tollData);
            log.info(String.valueOf(tollDataJson));
            // call ai vision model to detect vehicle type
            String aiResult = aiVisionService.analyzeImage(tollDataJson.get("image").asText());
            log.info("result from ai (type,confidence): " + aiResult);
            String detectedVehicleType = aiResult.split(",")[0];
            // add the detected vehicle type
            JsonNode updatedTollDataJson = (JsonNode) ((ObjectNode)tollDataJson).put("detectedVehicleType", detectedVehicleType);

            journalService.journal(updatedTollDataJson);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }
}
