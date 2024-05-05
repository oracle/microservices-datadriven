// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.controller;

import com.example.queuereader.model.AccountDetails;
import com.example.queuereader.service.AIVisionService;
import com.example.queuereader.service.CustomerDataService;
import com.example.queuereader.service.JournalService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class TollReaderReceiver {

    ObjectMapper objectMapper = new ObjectMapper();

    private JournalService journalService;
    private AIVisionService aiVisionService;
    private CustomerDataService customerDataService;

    public TollReaderReceiver(
        JournalService journalService, 
        AIVisionService aiVisionService,
        CustomerDataService customerDataService,
        MeterRegistry registry
    ) {
        this.journalService = journalService;
        this.aiVisionService = aiVisionService;
        this.customerDataService = customerDataService;
        registry.timer("process.toll.read", Tags.empty());
    }

    @JmsListener(destination = "TollGate")
    @Timed(value = "process.toll.read")
    public void receiveTollData(String tollData) {
        log.info("Received message {}", tollData);
        try {
            JsonNode tollDataJson = objectMapper.readTree(tollData);
            log.info(String.valueOf(tollDataJson));

            // check account
            log.info("Check that the tag, licensePlate and accountNumber match up");
            String tagId = tollDataJson.get("tagId").asText();
            String accountId = tollDataJson.get("accountNumber").asText();
            String licensePlate = tollDataJson.get("licensePlate").asText().split("-")[1];

            List<AccountDetails> accountDetails = customerDataService.getAccountDetails(licensePlate);
            boolean found = false;
            for (AccountDetails a : accountDetails) {
                if (a.getAccountNumber().equalsIgnoreCase(accountId) && a.getTagId().equalsIgnoreCase(tagId)) {
                    found = true; 
                }
            }
            if (found) {
                log.info("Details match, proceeding...");
            } else {
                log.info("Details do not match - so ignoring this message");
                return;
            }

            // call ai vision model to detect vehicle type
            log.info("Call the Vision AI Service to check if the vehicle photo matches the registration...");
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
