package com.example.queuereader.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.queuereader.model.TollData;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class QueueReader {

    //create ObjectMapper instance
    ObjectMapper objectMapper = new ObjectMapper();

    @JmsListener(destination = "TollGate")
    public void receiveMessage(String tollData) {
        System.out.println("Received tolldata <" + tollData + ">");
        TollData tollData1 = objectMapper.convertValue(tollData, TollData.class);
    }
}
