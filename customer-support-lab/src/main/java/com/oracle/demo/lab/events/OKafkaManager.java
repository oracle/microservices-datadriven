package com.oracle.demo.lab.events;

import jakarta.annotation.PostConstruct;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.concurrent.ExecutionException;

@Component
@Profile("events")
public class OKafkaManager {
    private static final Logger log = LoggerFactory.getLogger(OKafkaManager.class);

    private final AsyncTaskExecutor asyncTaskExecutor;
    private final Admin admin;
    private final TicketEventConsumer eventConsumer;
    private final String topic;

    public OKafkaManager(@Qualifier("applicationTaskExecutor") AsyncTaskExecutor asyncTaskExecutor,
                         Admin admin,
                         TicketEventConsumer eventConsumer,
                         @Value("${okafka.topic.tickets}") String topic) {
        this.asyncTaskExecutor = asyncTaskExecutor;
        this.admin = admin;
        this.eventConsumer = eventConsumer;
        this.topic = topic;
    }

    @PostConstruct
    public void init() {
        NewTopic newTopic = new NewTopic(topic, 1, (short) 1);
        try {
            admin.createTopics(Collections.singletonList(newTopic))
                    .all()
                    .get();
        } catch (ExecutionException | InterruptedException e) {
            if (e.getCause() instanceof TopicExistsException) {
                log.info("Topic {} already exists, skipping creation", newTopic);
            } else {
                throw new RuntimeException(e);
            }
        }
        asyncTaskExecutor.submit(eventConsumer);
    }
}
