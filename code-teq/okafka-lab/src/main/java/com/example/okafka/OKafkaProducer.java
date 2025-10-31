package com.example.okafka;

import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.oracle.okafka.clients.producer.KafkaProducer;

import java.time.Instant;
import java.util.Properties;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import static com.example.okafka.OKafka.TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class OKafkaProducer {

    public static void main(String[] args) throws InterruptedException {
        Properties props = getAuthenticationProperties();
        props.put("enable.idempotence", "true");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        Producer<String, String> producer = new KafkaProducer<>(props);
        Runnable producerThread = () -> {
            Instant now  = Instant.now();
            ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC_NAME, "Message: " + now);
            producer.send(record);
            System.out.println("Producer sent message: " + record.value());
        };



        int pauseMillis = 1000;
        String pm = System.getenv("PAUSE_MILLIS");
        if (pm != null && !pm.isEmpty()) {
            pauseMillis = Integer.parseInt(pm);
        }

        try (ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
        ) {
            System.out.println("Starting producer");
            scheduler.scheduleAtFixedRate(producerThread, 0, pauseMillis, TimeUnit.MILLISECONDS);
        }
        Thread.currentThread().join();
    }
}
