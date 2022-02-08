package com.oracle.developers.eventmesh.teq.okafka.service;


import com.oracle.developers.eventmesh.teq.okafka.config.producer.OKafkaProducerConfig;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.oracle.okafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.annotation.PreDestroy;
import java.util.Map;

@Service
public class OKafkaProducerService {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaProducerService.class);

    private KafkaProducer<String, String> kafkaProducer;

    private final OKafkaProducerConfig producerConfig;


    public OKafkaProducerService(OKafkaProducerConfig producerConfig) {
        Map<String, Object> prodConfig = producerConfig.producerConfig();
        for (Map.Entry<String, Object> entry : prodConfig.entrySet()) {
            LOG.info("teqProducerConfig Key='{}', value='{}'", entry.getKey(), entry.getValue());
        }
        this.producerConfig = producerConfig;
        this.kafkaProducer = new KafkaProducer<String, String>(producerConfig.producerConfig());
    }

    public void send(String topicName, String key, String message) {
        LOG.info("Sending message='{}' to topic='{}'", message, topicName);

        ProducerRecord prodRec = new ProducerRecord<String, String>(topicName, 0, key, message);
        LOG.info("Created ProdRec: {}"+ prodRec);

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

//    private void addCallback(String topicName, String message,
//                             ListenableFuture<SendResult<String, String>> kafkaResultFuture) {
//        kafkaResultFuture.addCallback(new ListenableFutureCallback<>() {
//            @Override
//            public void onFailure(Throwable throwable) {
//                LOG.error("Error while sending message {} to topic {}", message, topicName, throwable);
//            }
//
//            @Override
//            public void onSuccess(SendResult<String, String> result) {
//                RecordMetadata metadata = result.getRecordMetadata();
//                LOG.debug("Received new metadata. Topic: {}; Partition {}; Offset {}; Timestamp {}, at time {}",
//                        metadata.topic(),
//                        metadata.partition(),
//                        metadata.offset(),
//                        metadata.timestamp(),
//                        System.nanoTime());
//            }
//        });
//    }
}
