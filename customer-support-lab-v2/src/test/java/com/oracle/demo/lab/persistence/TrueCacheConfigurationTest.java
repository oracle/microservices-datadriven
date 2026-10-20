// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.persistence.TrueCacheTicketReader;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import com.oracle.spring.ucp.micrometer.UcpMicrometerAutoConfiguration;
import io.micrometer.core.instrument.binder.MeterBinder;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;

class TrueCacheConfigurationTest {
    @Test
    void defaultConfigurationCreatesLazyCacheReader() throws Exception {
        StandardEnvironment environment = new StandardEnvironment();
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
        String unreachableUrl = "jdbc:oracle:thin:@//localhost:1/NO_SERVICE";

        try (ConfigurableApplicationContext context = new SpringApplicationBuilder(CacheConfiguration.class)
                .environment(environment)
                .web(WebApplicationType.NONE)
                .properties("spring.main.log-startup-info=false",
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
    }

    @Test
    void bindsBothPoolsWithoutReplacingDefaultDataSource() throws Exception {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        try (ConfigurableApplicationContext context = new SpringApplicationBuilder(BothPoolsConfiguration.class)
                .web(WebApplicationType.NONE)
                .properties("spring.main.log-startup-info=false", "APP_DB_USERNAME=LAB_USER",
                        "APP_DB_PASSWORD=test-only", "TRUE_CACHE_JDBC_URL=jdbc:oracle:thin:@//localhost:1/NO_SERVICE")
                .run()) {
            PoolDataSource primary = context.getBean("primaryDataSource", PoolDataSource.class);
            assertSame(primary, context.getBean(PrimaryConsumer.class).dataSource());
            assertSame(context.getBean(TrueCacheTicketReader.class).dataSource(),
                    context.getBean("trueCacheDataSource"));
            context.getBean(MeterBinder.class).bindTo(registry);
            assertEquals(30, registry.get("db.client.connection.max")
                    .tag("db.client.connection.pool.name", "TestPrimaryPool").gauge().value());
            assertEquals(8, registry.get("db.client.connection.max")
                    .tag("db.client.connection.pool.name", "TrueCacheReadPool").gauge().value());
        } finally {
            registry.close();
        }
    }

    @Configuration(proxyBeanMethods = false)
    @Import({TrueCacheTicketReader.class, TrueCacheMetricsConfiguration.class,
            UcpMicrometerAutoConfiguration.class})
    static class BothPoolsConfiguration {
        @Bean
        PoolDataSource primaryDataSource() throws Exception {
            PoolDataSource pool = PoolDataSourceFactory.getPoolDataSource();
            pool.setConnectionPoolName("TestPrimaryPool");
            pool.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
            pool.setURL("jdbc:oracle:thin:@//localhost:1/NO_SERVICE");
            pool.setMinPoolSize(0);
            pool.setInitialPoolSize(0);
            pool.setMaxPoolSize(30);
            return pool;
        }

        @Bean
        PrimaryConsumer primaryConsumer(DataSource dataSource) {
            return new PrimaryConsumer(dataSource);
        }
    }

    record PrimaryConsumer(DataSource dataSource) {}
}
