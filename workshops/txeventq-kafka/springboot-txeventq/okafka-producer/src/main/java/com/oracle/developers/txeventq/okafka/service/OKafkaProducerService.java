/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.service;


import com.oracle.developers.txeventq.okafka.config.producer.OKafkaProducerConfig;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.oracle.okafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.annotation.PreDestroy;
import java.security.Provider;
import java.security.Security;
import java.util.Map;

@Service
public class OKafkaProducerService {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaProducerService.class);

    private final KafkaProducer<String, String> kafkaProducer;

    private final OKafkaProducerConfig producerConfig;


    public OKafkaProducerService(OKafkaProducerConfig producerConfig) {
        Map<String, Object> prodConfig = producerConfig.producerConfig();
        for (Map.Entry<String, Object> entry : prodConfig.entrySet()) {
            LOG.info("txeventqProducerConfig Key='{}', value='{}'", entry.getKey(), entry.getValue());
        }
        this.producerConfig = producerConfig;
        this.kafkaProducer = new KafkaProducer<String, String>(producerConfig.producerConfig());
        addOraclePKIProvider();
    }

    public void send(String topicName, String key, String message) {
        LOG.info("Sending message='{}' to topic='{}'", message, topicName);

        ProducerRecord<String, String> prodRec = new ProducerRecord<>(topicName, 0, key, message);
        LOG.info("Created ProdRec: {}", prodRec);

        kafkaProducer.send(prodRec);
        LOG.info("Sent message key: {} ", key);
    }

    public void send(ProducerRecord<String, String> prodRec) {
        LOG.info("Sending message='{}' to topic='{}'", prodRec.value(), prodRec.topic());
        kafkaProducer.send(prodRec);
    }

    @PreDestroy
    public void close() {
        if (kafkaProducer != null) {
            LOG.info("Closing kafka producer!");
            kafkaProducer.close();
        }
    }

    private static void addOraclePKIProvider() {
        System.out.println("Installing Oracle PKI provider.");
        Provider oraclePKI = new oracle.security.pki.OraclePKIProvider();
        Security.insertProviderAt(oraclePKI,3);
    }
}
