// Copyright (c) 2024, 2025, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32;

import com.example.common.filter.LoggingFilterConfig;
import com.example.common.ucp.UCPTelemetry;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Import;

@SpringBootApplication
@EnableDiscoveryClient
@Import({ LoggingFilterConfig.class, UCPTelemetry.class })
public class Customer32Application {

    public static void main(String[] args) {
        SpringApplication.run(Customer32Application.class, args);
    }

}
