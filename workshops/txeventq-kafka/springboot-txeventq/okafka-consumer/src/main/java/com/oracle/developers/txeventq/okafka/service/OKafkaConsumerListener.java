package com.oracle.developers.txeventq.okafka.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import javax.annotation.PreDestroy;
import java.util.concurrent.TimeUnit;

@Component
public class OKafkaConsumerListener implements CommandLineRunner {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaConsumerListener.class);

    @Autowired
    private OKafkaConsumerService consumer;

    @Override
    public void run(String... args) throws Exception {
        LOG.debug("OKafkaConsumerListener Start Listening!");
        while(true) {
            consumer.startReceive();
            try {
                TimeUnit.SECONDS.sleep(5);
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
            }
        }
    }

    @PreDestroy
    public void stop() {
        if (consumer != null) {
            LOG.info("Closing consumer start!");
            consumer.stopReceive();
        }
    }
}
