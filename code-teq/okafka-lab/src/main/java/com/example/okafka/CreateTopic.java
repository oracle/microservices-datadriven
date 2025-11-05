package com.example.okafka;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.oracle.okafka.clients.admin.AdminClient;

import java.util.List;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

import static com.example.okafka.OKafka.TOPIC_NAME;
import static com.example.okafka.OKafka.TRANSACTIONAL_TOPIC_NAME;
import static com.example.okafka.OKafkaAuthentication.getAuthenticationProperties;

public class CreateTopic {
    public static void main(String[] args) {
        // Authentication properties to connect to Kafka
        Properties props = getAuthenticationProperties();

        try (Admin admin = AdminClient.create(props)) {
            NewTopic testTopic = new NewTopic(TOPIC_NAME, 1, (short) 1);
            NewTopic transactionalTestTopic = new NewTopic(TRANSACTIONAL_TOPIC_NAME, 1, (short) 1);
            admin.createTopics(List.of(testTopic, transactionalTestTopic))
                    .all()
                    .get();
            System.out.println("[ADMIN] Created topic: " + testTopic.name());
        } catch (ExecutionException | InterruptedException e) {
            if (e.getCause() instanceof TopicExistsException) {
                System.out.println("[ADMIN] Topic already exists");
            } else {
                throw new RuntimeException(e);
            }
        }
    }
}
