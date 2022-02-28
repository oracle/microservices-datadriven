package com.oracle.developers.kafka.producer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;

@SpringBootApplication
@ComponentScan(basePackages = "com.oracle.developers.kafka",
        excludeFilters =
        @ComponentScan.Filter(type= FilterType.REGEX,
                pattern="com\\.oracle\\.developers\\.kafka\\.config\\.consumer\\..*"))
public class KafkaProducerApplication {
    private static final Logger LOG = LoggerFactory.getLogger(KafkaProducerApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(KafkaProducerApplication.class, args);
    }
}
