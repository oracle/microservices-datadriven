package com.example.queuereader.controller;

import com.example.queuereader.model.TollData;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class TollReaderReceiver {

    ObjectMapper objectMapper = new ObjectMapper();

    @JmsListener(destination = "TollGate")
    public void receiveTollData(String tollData) {
        log.info("Received message {}", tollData);
        try {
            JsonNode tollDataJson = objectMapper.readTree(tollData);
            log.info(String.valueOf(tollDataJson));
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }
}
