package com.oracle.developers.txeventq.okafka.service;

import com.oracle.developers.txeventq.okafka.config.consumer.OKafkaConsumerConfig;
import com.oracle.developers.txeventq.okafka.config.data.OKafkaConfigData;
import com.oracle.developers.txeventq.okafka.config.data.OKafkaTopicConfigData;
import org.oracle.okafka.clients.consumer.ConsumerRecord;
import org.oracle.okafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.Provider;
import java.security.Security;
import java.time.Duration;
import java.util.List;
import java.util.Map;

@Service
public class OKafkaConsumerService {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaConsumerService.class);

    private final OKafkaConfigData configData;
    private final OKafkaTopicConfigData topicConfigData;
    private final OKafkaConsumerConfig consumerSetup;

    private KafkaConsumer<String, String> consumer = null;

    public OKafkaConsumerService(OKafkaConfigData configData, OKafkaTopicConfigData topicConfigData, OKafkaConsumerConfig consumerSetup) {
        this.configData = configData;
        this.topicConfigData = topicConfigData;
        this.consumerSetup = consumerSetup;
        addOraclePKIProvider();
    }

    public void startReceive() {
        Map<String, Object> configMap = consumerSetup.consumerConfig();

        consumer = new KafkaConsumer<>(configMap);

        LOG.debug("Subscribe {}", topicConfigData.getTopicName());
        consumer.subscribe(List.of(topicConfigData.getTopicName()));
        ConsumerRecords<String, String> records;
        try {
            // TODO There is a issue with elapsedTime usually greater timeoutMs
            LOG.debug("Start to Receive");
            records = consumer.poll(Duration.ofMillis(25000));
            LOG.debug("Records: {}", records.count());

            for (ConsumerRecord<String, String> record : records) {
                LOG.debug("topic = {}, partition=  {}, key= {}, value = {}}",
                        record.topic(), record.partition(), record.key(), record.value());
                this.receive(record.key(), record.value());
            }
            consumer.commitSync();
        }catch(Exception ex) {
            ex.printStackTrace();
        } finally {
            consumer.close();
        }
    }

    public void stopReceive() {
        if (consumer != null) consumer.close();
    }

    public void receive(String key, String message) {
        LOG.info("message received {}. using key {}. sending to processing: Thread id {}", message, key, Thread.currentThread().getId());
        //inventoryService.removeInventory(message);
    }

    private static void addOraclePKIProvider() {
        System.out.println("Installing Oracle PKI provider.");
        Provider oraclePKI = new oracle.security.pki.OraclePKIProvider();
        Security.insertProviderAt(oraclePKI,3);
    }
}
