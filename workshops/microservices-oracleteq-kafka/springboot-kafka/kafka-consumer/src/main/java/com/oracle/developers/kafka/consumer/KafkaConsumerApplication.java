package com.oracle.developers.kafka.consumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.SeekToCurrentErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

@SpringBootApplication
@ComponentScan(basePackages = "com.oracle.developers.kafka",
        excludeFilters =
        @ComponentScan.Filter(type= FilterType.REGEX,
                pattern="com\\.oracle\\.developers\\.kafka\\.config\\.producer\\..*"))
public class KafkaConsumerApplication {

    public static void main(String[] args) {
        SpringApplication.run(KafkaConsumerApplication.class, args);
    }


    /*
     * Boot will autowire this into the container factory.
     */
    @Bean
    public SeekToCurrentErrorHandler errorHandler(KafkaOperations<Object, Object> template) {
        return new SeekToCurrentErrorHandler(
                new DeadLetterPublishingRecoverer(template), new FixedBackOff(1000L, 2));
    }
}
