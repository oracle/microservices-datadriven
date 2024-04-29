package com.example.queuereader.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class TollReaderReceiver {

    @JmsListener(destination = "TollGaate")
    public void receive(String message) {
        log.info("Received message {}", message);
    }
}
