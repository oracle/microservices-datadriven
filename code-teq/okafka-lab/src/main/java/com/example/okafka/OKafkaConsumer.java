package com.example.okafka;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;

import java.time.Duration;
import java.util.List;
import java.util.Properties;

import static com.example.okafka.OKafka.TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class OKafkaConsumer {
    public static void main(String[] args) {
        Properties props = getAuthenticationProperties();

        // Note the use of standard Kafka properties for OKafka configuration.
        props.put("group.id" , "TEST_CONSUMER");
        props.put("enable.auto.commit","false");
        props.put("max.poll.records", 50);
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("auto.offset.reset", "earliest");

        Consumer<String, String> consumer = new KafkaConsumer<>(props);

        consumer.subscribe(List.of(TOPIC_NAME));
        System.out.println("Subscribed to topic " + TOPIC_NAME);
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(3));
            for (ConsumerRecord<String, String> record : records) {
                System.out.println("Consumed record: " + record.value());
            }
        }
    }
}
