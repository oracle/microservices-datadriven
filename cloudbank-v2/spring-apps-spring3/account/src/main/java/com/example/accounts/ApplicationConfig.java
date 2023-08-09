// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts;

import java.net.URISyntaxException;
import java.util.logging.Logger;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.narayana.lra.client.NarayanaLRAClient;

@Configuration
public class ApplicationConfig {
    private static final Logger log = Logger.getLogger(ApplicationConfig.class.getName());

    public ApplicationConfig(@Value("${lra.coordinator.url}") String lraCoordinatorUrl) {
        log.info(NarayanaLRAClient.LRA_COORDINATOR_URL_KEY + " = " + lraCoordinatorUrl);
        System.getProperties().setProperty(NarayanaLRAClient.LRA_COORDINATOR_URL_KEY, lraCoordinatorUrl);
    }

    @Bean
    public NarayanaLRAClient NarayanaLRAClient() throws URISyntaxException {
        return new NarayanaLRAClient();
    }
}