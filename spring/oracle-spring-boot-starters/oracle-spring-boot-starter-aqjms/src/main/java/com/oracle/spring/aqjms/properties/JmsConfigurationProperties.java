package com.oracle.spring.aqjms.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "oracle.aq")
public class JmsConfigurationProperties {
    private String url;
    private String username;
    private String password;
    private String queue;

    public JmsConfigurationProperties(JmsConfigurationProperties properties) {
        this.url = properties.url;
        this.username = properties.username;
        this.password = properties.password;
        this.queue = properties.queue;
    }

    public String getUrl() {
        return url;
    }
    
    public void setUrl(String url) {
        this.url = url;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public String getQueue() {
        return queue;
    }
    
    public void setQueue(String queue) {
        this.queue = queue;
    }
}