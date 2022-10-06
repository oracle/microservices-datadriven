/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.service;

import com.oracle.developers.txeventq.okafka.config.data.LabEventData;
import com.oracle.developers.txeventq.okafka.config.data.OKafkaConfigData;
import com.oracle.developers.txeventq.okafka.config.data.OKafkaTopicConfigData;
import org.oracle.okafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class OKafkaEventProducer {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaEventProducer.class);

    private final OKafkaConfigData kafkaConfigData;
    private final OKafkaTopicConfigData topicConfigData;
    private final OKafkaProducerService producer;

    public OKafkaEventProducer(OKafkaConfigData kafkaConfigData, OKafkaTopicConfigData topicConfigData, OKafkaProducerService producer) {
        this.kafkaConfigData = kafkaConfigData;
        this.topicConfigData = topicConfigData;
        this.producer = producer;
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
            producer.send(record);

            LOG.info("validateDataAndSendEvent committed and sent message in the same tx with payload: {}", newEvent);
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
