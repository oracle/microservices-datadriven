package com.example.okafka;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.oracle.okafka.clients.producer.KafkaProducer;

import java.sql.*;
import java.time.Instant;
import java.util.Properties;

import static com.example.okafka.OKafka.TRANSACTIONAL_TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class TransactionalProducer {
    public static void main(String[] args) throws InterruptedException, SQLException {
        Properties props = getAuthenticationProperties();
        props.put("enable.idempotence", "true");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.LongSerializer");
        // This property is required for transactional producers
        props.put("oracle.transactional.producer", "true");
        KafkaProducer<String, Long> producer = new KafkaProducer<>(props);
        producer.initTransactions();

        int pauseMillis = 1000;
        String pm = System.getenv("PAUSE_MILLIS");
        if (pm != null && !pm.isEmpty()) {
            pauseMillis = Integer.parseInt(pm);
        }

        while (true) {
            Instant now  = Instant.now();
            long id;
            producer.beginTransaction();
            Connection conn = producer.getDBConnection();

            final String sql = "insert into log (produced) values (?)";
            try (PreparedStatement ps = conn.prepareStatement(sql, new String[]{"id",})) {
                ps.setDate(1, new Date(now.toEpochMilli()));
                ps.executeUpdate();

                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    id = generatedKeys.getLong(1);
                } else {
                    throw new SQLException("Create log message failed, no ID obtained");
                }
            }

            ProducerRecord<String, Long> record = new ProducerRecord<>(TRANSACTIONAL_TOPIC_NAME, id);
            producer.send(record);

            producer.commitTransaction();
            System.out.println("Producer sent message: " + record.value());

            Thread.sleep(pauseMillis);
        }
    }
}
