package com.oracle.spring.aqjms;

import org.springframework.boot.context.properties.ConfigurationProperties;
import lombok.Getter;
import lombok.Setter;

@ConfigurationProperties(prefix = "oracle.aq")
@Getter 
@Setter
public class AqJmsConfigurationProperties {
    private String url;
    private String username;
    private String password;
    private String queue;
}