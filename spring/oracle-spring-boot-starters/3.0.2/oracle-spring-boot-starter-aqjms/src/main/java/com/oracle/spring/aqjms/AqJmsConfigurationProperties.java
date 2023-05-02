// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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
