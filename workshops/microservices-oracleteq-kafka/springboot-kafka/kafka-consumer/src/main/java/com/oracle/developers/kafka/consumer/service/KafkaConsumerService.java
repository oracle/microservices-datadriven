package com.oracle.developers.kafka.consumer.service;

import com.oracle.developers.kafka.config.data.KafkaConfigData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationStartedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class KafkaConsumerService {
    private static final Logger LOG = LoggerFactory.getLogger(KafkaConsumerService.class);

    private final KafkaListenerEndpointRegistry kafkaListenerEndpointRegistry;

    private final KafkaConfigData kafkaConfigData;

    public KafkaConsumerService(KafkaListenerEndpointRegistry kafkaListenerEndpointRegistry, KafkaConfigData kafkaConfigData) {
        this.kafkaListenerEndpointRegistry = kafkaListenerEndpointRegistry;
        this.kafkaConfigData = kafkaConfigData;
    }

    @EventListener
    public void onAppStarted(ApplicationStartedEvent event) {
        kafkaListenerEndpointRegistry.getListenerContainer("kafkaTopicListener").start();
    }

    @KafkaListener(id = "kafkaTopicListener", topics = "${kafka-topic-config.topic-name}", groupId = "${kafka-consumer-config.consumer-group-id}")
    public void receive(@Payload List<String> messages,
                        @Header(KafkaHeaders.RECEIVED_MESSAGE_KEY) List<Integer> keys,
                        @Header(KafkaHeaders.RECEIVED_PARTITION_ID) List<Integer> partitions,
                        @Header(KafkaHeaders.OFFSET) List<Long> offsets) {
        LOG.info("{} number of message received with keys {}, partitions {} and offsets {}, " +
                        "sending it to processing: Thread id {}",
                messages.size(),
                keys.toString(),
                partitions.toString(),
                offsets.toString(),
                Thread.currentThread().getId());

        messages.forEach(
                (message) -> {
                    LOG.info("message {}", message);
                }
        );
    }
}
