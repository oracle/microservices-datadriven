package com.oracle.spring.aqjms.properties;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

@EnableConfigurationProperties(JmsConfigurationProperties.class)
public class JmsAutoConfiguration {
    @Bean
    @Primary
    JmsConfigurationProperties jmsComponent(JmsConfigurationProperties properties) {
        return new JmsConfigurationProperties(properties);
    }
}