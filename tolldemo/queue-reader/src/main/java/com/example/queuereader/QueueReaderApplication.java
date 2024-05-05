// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader;

import javax.jms.ConnectionFactory;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.DependsOn;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;

@EnableJms
@SpringBootApplication
@EnableFeignClients
public class QueueReaderApplication {

    public static void main(String[] args) {
        SpringApplication.run(QueueReaderApplication.class, args);
    }

    @Bean
    @DependsOn("aqJmsConnectionFactory")
    public DefaultJmsListenerContainerFactory jmsListenerContainerFactory(ApplicationContext context) {
        DefaultJmsListenerContainerFactory factory = 
            new DefaultJmsListenerContainerFactory();
        ConnectionFactory connectionFactory = (ConnectionFactory) context.getBean("aqJmsConnectionFactory");
        factory.setConnectionFactory(connectionFactory);
        factory.setConcurrency("1-1");
        return factory;
    }

}
