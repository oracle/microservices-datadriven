package com.oracle.spring.aqjms.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;
import lombok.Getter;
import lombok.Setter;

@ConfigurationProperties(prefix = "oracle.aq")
@Getter 
@Setter
public class JmsConfigurationProperties {
    private String url;
    private String username;
    private String password;
    private String queue;
}