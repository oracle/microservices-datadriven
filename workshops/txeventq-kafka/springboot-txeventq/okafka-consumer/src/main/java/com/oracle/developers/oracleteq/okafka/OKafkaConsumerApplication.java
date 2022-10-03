/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;

@SpringBootApplication
@ComponentScan(basePackages = "com.oracle.developers.txeventq.okafka",
        excludeFilters =
        @ComponentScan.Filter(type= FilterType.REGEX,
                pattern="com\\.oracle\\.developers\\.txeventq\\.okafka\\.config\\.producer\\..*"))
public class OKafkaConsumerApplication {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaConsumerApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(OKafkaConsumerApplication.class, args);
        LOG.info("OKafka Consumer Application Running!");
    }
}
