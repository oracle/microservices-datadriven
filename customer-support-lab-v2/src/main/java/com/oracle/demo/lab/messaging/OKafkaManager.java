// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.messaging;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
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

import java.util.List;
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
        NewTopic newTopic = new NewTopic(topic, 1, (short) 0);
        try {
            boolean exists = admin.listTopics().names().get().stream()
                    .anyMatch(name -> name.equalsIgnoreCase(topic));
            if (exists) {
                log.info("Topic {} already exists", topic);
            } else {
                admin.createTopics(List.of(newTopic)).all().get();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while preparing topic " + topic, e);
        } catch (ExecutionException e) {
            if (e.getCause() instanceof TopicExistsException) {
                log.info("Topic {} already exists", topic);
            } else {
                throw new IllegalStateException("Could not prepare topic " + topic, e);
            }
        }
        asyncTaskExecutor.submit(eventConsumer);
    }

    @PreDestroy
    public void stop() {
        eventConsumer.stop();
    }
}
