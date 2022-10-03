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
				pattern="com\\.oracle\\.developers\\.txeventq\\.okafka\\.config\\.consumer\\..*"))
public class OKafkaProducerApplication {

	private static final Logger LOG = LoggerFactory.getLogger(OKafkaProducerApplication.class);

	public static void main(String[] args) {
		SpringApplication.run(OKafkaProducerApplication.class, args);
		LOG.info("OKafka Producer Application Running!");

	}
}
