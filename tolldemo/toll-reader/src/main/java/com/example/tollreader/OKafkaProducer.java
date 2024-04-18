package com.example.tollreader;

import org.springframework.stereotype.Service;

import jakarta.json.JsonObject;

@Service
public class OKafkaProducer {
    
    public void sendTollData(JsonObject tollData) {
        // okafka.send(bkh blah blah)
    }

}
