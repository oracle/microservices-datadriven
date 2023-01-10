package com.oracle.spring.aqjms.properties;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

import com.oracle.spring.aqjms.config.JmsConfiguration;

@EnableConfigurationProperties(JmsConfigurationProperties.class)
public class JmsAutoConfiguration {
    @Bean
    @Primary
    JmsConfiguration jmsConfiguration(JmsConfigurationProperties properties) {
        return new JmsConfiguration(properties);
    }
}