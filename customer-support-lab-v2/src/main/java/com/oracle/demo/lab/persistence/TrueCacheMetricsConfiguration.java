// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.persistence;

import oracle.ucp.jdbc.PoolDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Makes the reader's pool visible to the starter's existing UCP MeterBinder. */
@Configuration(proxyBeanMethods = false)
public class TrueCacheMetricsConfiguration {
    // Exclude this read-only pool from default DataSource injection and primary
    // datasource auto-configuration. The reader retains lifecycle ownership.
    @Bean(defaultCandidate = false, destroyMethod = "")
    PoolDataSource trueCacheDataSource(TrueCacheTicketReader reader) {
        return reader.dataSource();
    }
}
