package com.oracle.developers.oracleteq.okafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;

@SpringBootApplication
@ComponentScan(basePackages = "com.oracle.developers.oracleteq.okafka",
        excludeFilters =
        @ComponentScan.Filter(type= FilterType.REGEX,
                pattern="com\\.oracle\\.developers\\.oracleteq\\.okafka\\.config\\.producer\\..*"))
public class OKafkaConsumerApplication {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaConsumerApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(OKafkaConsumerApplication.class, args);
        LOG.info("OKafka Consumer Application Running!");
    }
}
