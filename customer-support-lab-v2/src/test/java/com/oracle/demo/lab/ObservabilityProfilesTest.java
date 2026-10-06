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

class ObservabilityProfilesTest {
    @Test
    void coreDoesNotExportOtlp() {
        try (ConfigurableApplicationContext context = start("events,demo-failures")) {
            Environment environment = context.getEnvironment();
            assertEquals("false", environment.getProperty("management.otlp.metrics.export.enabled"));
            assertEquals("false", environment.getProperty("management.tracing.export.otlp.enabled"));
        }
    }

    @Test
    void observabilityProfileExportsMetricsAndTraces() {
        try (ConfigurableApplicationContext context = start("events,observability")) {
            Environment environment = context.getEnvironment();
            assertEquals("true", environment.getProperty("management.otlp.metrics.export.enabled"));
            assertEquals("true", environment.getProperty("management.tracing.export.otlp.enabled"));
            assertEquals("false", environment.getProperty("management.logging.export.otlp.enabled"));
        }
    }

    private ConfigurableApplicationContext start(String profiles) {
        StandardEnvironment environment = new StandardEnvironment();
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
        return new SpringApplicationBuilder(EmptyConfiguration.class)
                .environment(environment)
                .web(WebApplicationType.NONE)
                .properties("spring.profiles.active=" + profiles, "spring.main.log-startup-info=false")
                .run();
    }

    @Configuration(proxyBeanMethods = false)
    static class EmptyConfiguration {
    }
}
