package com.example.okafka;

import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.oracle.okafka.clients.producer.KafkaProducer;

import java.time.Instant;
import java.util.Properties;

import static com.example.okafka.OKafka.TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class OKafkaProducer {

    public static void main(String[] args) throws InterruptedException {
        Properties props = getAuthenticationProperties();
        props.put("enable.idempotence", "true");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        Producer<String, String> producer = new KafkaProducer<>(props);

        int pauseMillis = 1000;
        String pm = System.getenv("PAUSE_MILLIS");
        if (pm != null && !pm.isEmpty()) {
            pauseMillis = Integer.parseInt(pm);
        }

        while (true) {
            Instant now  = Instant.now();
            ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC_NAME, "Message: " + now);
            producer.send(record);
            System.out.println("Producer sent message: " + record.value());

            Thread.sleep(pauseMillis);
        }
    }
}
