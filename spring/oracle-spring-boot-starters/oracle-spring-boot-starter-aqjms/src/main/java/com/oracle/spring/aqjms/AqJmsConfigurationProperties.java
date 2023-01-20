package com.oracle.spring.aqjms;

/*-
 * #%L
 * Oracle Spring Boot Starter - AQ JMS
 * %%
 * Copyright (C) 2023 Oracle America, Inc.
 * %%
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 * #L%
 */

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
