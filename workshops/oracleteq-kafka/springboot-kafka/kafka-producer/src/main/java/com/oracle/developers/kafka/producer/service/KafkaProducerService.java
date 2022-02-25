package com.oracle.developers.kafka.producer.service;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.util.concurrent.ListenableFutureCallback;

import javax.annotation.PreDestroy;

@Service
public class KafkaProducerService {
    private static final Logger LOG = LoggerFactory.getLogger(KafkaProducerService.class);

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    public void send(String topicName, String key, String message) {
        LOG.info("Sending message='{}' to topic='{}'", message, topicName);
        ListenableFuture<SendResult<String, String>> kafkaResultFuture =
                kafkaTemplate.send(topicName, key, message);
    }

    public void send(ProducerRecord<String, String> producer) {
        LOG.info("Sending message='{}' to topic='{}'", producer.value(), producer.topic());
        ListenableFuture<SendResult<String, String>> kafkaResultFuture =
                kafkaTemplate.send(producer);
    }

    @PreDestroy
    public void close() {
        if (kafkaTemplate != null) {
            LOG.info("Closing kafka producer!");
            kafkaTemplate.destroy();
        }
    }

    private void addCallback(String topicName, String message,
                             ListenableFuture<SendResult<String, String>> kafkaResultFuture) {
        kafkaResultFuture.addCallback(new ListenableFutureCallback<>() {
            @Override
            public void onFailure(Throwable throwable) {
                LOG.error("Error while sending message {} to topic {}", message, topicName, throwable);
            }

            @Override
            public void onSuccess(SendResult<String, String> result) {
                RecordMetadata metadata = result.getRecordMetadata();
                LOG.debug("Received new metadata. Topic: {}; Partition {}; Offset {}; Timestamp {}, at time {}",
                        metadata.topic(),
                        metadata.partition(),
                        metadata.offset(),
                        metadata.timestamp(),
                        System.nanoTime());
            }
        });
    }
}
