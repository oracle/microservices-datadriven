package com.oracle.developers.kafka.producer.service;

import com.oracle.developers.kafka.config.data.KafkaConfigData;
import com.oracle.developers.kafka.config.data.KafkaTopicConfigData;
import com.oracle.developers.kafka.config.data.LabEventData;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class KafkaEventProducer {
    private static final Logger LOG = LoggerFactory.getLogger(KafkaEventProducer.class);

    private final KafkaConfigData kafkaConfigData;
    private final KafkaTopicConfigData topicConfigData;
    private final KafkaProducerService kafkaProducer;

    public KafkaEventProducer(KafkaConfigData kafkaConfigData, KafkaTopicConfigData topicConfigData, KafkaProducerService kafkaProducer) {
        this.kafkaConfigData = kafkaConfigData;
        this.topicConfigData = topicConfigData;
        this.kafkaProducer = kafkaProducer;
    }

    public String validateDataAndSendEvent(LabEventData newEvent) {
        LOG.info("validateDataAndSendEvent: id {}, message {} ", newEvent.getId(), newEvent.getMessage());

        String statusMessage = "Successful";

        try {
            validateEvent(newEvent.getId(), newEvent.getMessage());
            LOG.info("validateDataAndSendEvent validateEvent successful about to send event message...");

            String topicEvent = topicConfigData.getTopicName();
            LOG.info("validateDataAndSendEvent topic: {}", topicEvent);

            String key = newEvent.getId();

            // Sending Order for Processing Queue
            ProducerRecord<String, String> record = new ProducerRecord<>(topicEvent, 0, key, newEvent.getAvroRecord().toString());
            kafkaProducer.send(record);

            LOG.info("validateDataAndSendEvent committed JSON order sent message in the same tx with payload: {}", newEvent);
            statusMessage = "Successful";

        } catch (Exception ex) {
            LOG.error("validateDataAndSendEvent failed with exception: {}", ex);
            statusMessage = "Failed";
        }
        return statusMessage;
    }

    //TODO Write Order Validation Code.
    private void validateEvent(String id, String message)  throws Exception {
        LOG.info("validatingEvent.....");
    }

}
