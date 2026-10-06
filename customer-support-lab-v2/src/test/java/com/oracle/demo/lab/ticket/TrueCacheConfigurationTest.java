// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import oracle.ucp.jdbc.PoolDataSource;
import org.junit.jupiter.api.Test;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;

class TrueCacheConfigurationTest {
    @Test
    void baseConfigurationCreatesLazyCacheReaderWithoutAnExtraProfile() throws Exception {
        StandardEnvironment environment = new StandardEnvironment();
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
        String unreachableUrl = "jdbc:oracle:thin:@//localhost:1/NO_SERVICE";

        try (ConfigurableApplicationContext context = new SpringApplicationBuilder(CacheConfiguration.class)
                .environment(environment)
                .web(WebApplicationType.NONE)
                .properties("spring.profiles.active=events", "spring.main.log-startup-info=false",
                        "APP_DB_USERNAME=LAB_USER", "APP_DB_PASSWORD=test-only",
                        "TRUE_CACHE_JDBC_URL=" + unreachableUrl)
                .run()) {
            TrueCacheTicketReader reader = context.getBean(TrueCacheTicketReader.class);
            PoolDataSource pool = (PoolDataSource) ReflectionTestUtils.getField(reader, "pool");

            assertEquals("TRUEFREE", ReflectionTestUtils.getField(reader, "expectedDbUniqueName"));
            assertEquals(unreachableUrl, pool.getURL());
            assertEquals("LAB_USER", pool.getUser());
            assertEquals(0, pool.getInitialPoolSize());
            assertEquals(0, pool.getMinPoolSize());
            assertEquals(8, pool.getMaxPoolSize());
        }
    }

    @Configuration(proxyBeanMethods = false)
    @Import(TrueCacheTicketReader.class)
    static class CacheConfiguration {
        @Bean
        RowMapper<SupportTicket> ticketRowMapper() {
            return (rows, rowNumber) -> new SupportTicket(rows);
        }
    }
}
