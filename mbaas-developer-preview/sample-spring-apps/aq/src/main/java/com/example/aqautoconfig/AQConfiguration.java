// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.aqautoconfig;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import com.example.aq.AQComponent;

@EnableConfigurationProperties(AQProperties.class)
public class AQConfiguration {
    @Bean
    @Primary
    AQComponent aqComponent(AQProperties properties) {
      return new AQComponent(properties);
    }
}
