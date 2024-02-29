// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.oracle.spring.aqjms;

import org.springframework.boot.context.properties.ConfigurationProperties;
import lombok.Getter;
import lombok.Setter;

/**
 * Configuration properties for the Oracle Spring Boot Starter for AQ/TxEventQ JMS
 */
@ConfigurationProperties(prefix = "spring.datasource")
@Getter 
@Setter
public class AqJmsConfigurationProperties {
    /**
     * Database URL, e.g. `jdbc:oracle:thin:@//172.17.0.2:1521/pdb1`
     */
    private String url;

    /**
     * Username to connect to database, e.g. `dave`
     */
    private String username;

    /**
     * Password to connect to database.
     */
    private String password;

}
