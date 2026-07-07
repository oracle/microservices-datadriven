package com.example.okafka;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Properties;

import static com.example.okafka.OKafka.TRANSACTIONAL_TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class TransactionalConsumer {
    public static void main(String[] args) throws SQLException {
        Properties props = getAuthenticationProperties();

        // Note the use of standard Kafka properties for OKafka configuration.
        props.put("group.id" , "TRANSACTIONAL_CONSUMER");
        props.put("enable.auto.commit","false");
        props.put("max.poll.records", 50);
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.LongDeserializer");
        props.put("auto.offset.reset", "earliest");

        KafkaConsumer<String, Long> consumer = new KafkaConsumer<>(props);

        consumer.subscribe(List.of(TRANSACTIONAL_TOPIC_NAME));
        System.out.println("Subscribed to topic " + TRANSACTIONAL_TOPIC_NAME);
        while (true) {
            Connection conn = consumer.getDBConnection();
            String sql = "update log set consumed = ? where id = ?";
            ConsumerRecords<String, Long> records = consumer.poll(Duration.ofSeconds(3));
            for (ConsumerRecord<String, Long> record : records) {
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setDate(1, new Date(Instant.now().toEpochMilli()));
                    ps.setLong(2, record.value());
                    ps.executeUpdate();
                }
                System.out.println("Consumed record: " + record.value());
            }

            consumer.commitSync();
        }
    }
}
