// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab;

import org.junit.jupiter.api.Test;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.env.StandardEnvironment;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ObservabilityConfigurationTest {
    @Test
    void defaultConfigurationExportsMetricsTracesAndLogs() {
        try (ConfigurableApplicationContext context = start()) {
            Environment environment = context.getEnvironment();
            assertEquals("true", environment.getProperty("management.otlp.metrics.export.enabled"));
            assertEquals("true", environment.getProperty("management.tracing.export.otlp.enabled"));
            assertEquals("true", environment.getProperty("management.logging.export.otlp.enabled"));
            assertEquals("logstash", environment.getProperty("logging.structured.format.console"));
            assertEquals("oci-genai", environment.getProperty("spring.ai.model.chat"));
            assertEquals("oci-genai", environment.getProperty("spring.ai.model.embedding"));
            assertEquals("1536", environment.getProperty("spring.ai.oci.genai.embedding.dimensions"));
        }
    }

    private ConfigurableApplicationContext start() {
        StandardEnvironment environment = new StandardEnvironment();
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
        return new SpringApplicationBuilder(EmptyConfiguration.class)
                .environment(environment)
                .web(WebApplicationType.NONE)
                .properties("spring.main.log-startup-info=false")
                .run();
    }

    @Configuration(proxyBeanMethods = false)
    static class EmptyConfiguration {
    }
}
