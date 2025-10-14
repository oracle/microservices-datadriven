// Copyright (c) 2025, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.common.ucp;

import javax.sql.DataSource;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.metrics.BatchCallback;
import io.opentelemetry.api.metrics.DoubleHistogram;
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.metrics.ObservableLongMeasurement;
import io.opentelemetry.instrumentation.api.incubator.semconv.db.DbConnectionPoolMetrics;
import io.opentelemetry.instrumentation.oracleucp.v11_2.OracleUcpTelemetry;
import io.opentelemetry.instrumentation.spring.autoconfigure.OpenTelemetryAutoConfiguration;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.AutoConfigureAfter;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@AutoConfigureAfter(OpenTelemetryAutoConfiguration.class)
@AutoConfiguration
public class UCPTelemetry {

    @Autowired
    private DataSource connectionPool;

    private OracleUcpTelemetry ucpTelemetry;
    private OpenTelemetry openTelemetry;

    public UCPTelemetry(OpenTelemetry openTelemetry) {
        this.ucpTelemetry = OracleUcpTelemetry.create(openTelemetry);
        this.openTelemetry = openTelemetry;
    }

    private BatchCallback additionMetrics;

    @PostConstruct
    protected void configure() throws Exception {
        UniversalConnectionPool universalConnectionPool = UniversalConnectionPoolManagerImpl
                .getUniversalConnectionPoolManager()
                .getConnectionPool(connectionPool.unwrap(PoolDataSource.class).getConnectionPoolName());
        this.ucpTelemetry.registerMetrics(universalConnectionPool);
        DbConnectionPoolMetrics metrics = DbConnectionPoolMetrics.create(
                openTelemetry, "obaas-ucp", universalConnectionPool.getName());

        DoubleHistogram connectionCreateTime = metrics.connectionCreateTime();
        DoubleHistogram connectionUseTime = metrics.connectionUseTime();
        LongCounter connectionTimeOuts = metrics.connectionTimeouts();
        DoubleHistogram connectionWaitTime = metrics.connectionWaitTime();
        ObservableLongMeasurement connections = metrics.connections();

        Attributes attributes = metrics.getAttributes();

        additionMetrics = metrics.batchCallback(
                () -> {
                    connectionUseTime.record(
                            universalConnectionPool.getStatistics().getCumulativeConnectionUseTime(), attributes);
                    connectionWaitTime.record(
                            universalConnectionPool.getStatistics().getCumulativeConnectionWaitTime(), attributes);
                    connectionCreateTime.record(universalConnectionPool.getStatistics().getAverageConnectionWaitTime(),
                            attributes);
                    connectionTimeOuts.add(
                            universalConnectionPool.getStatistics().getCumulativeFailedConnectionWaitCount(),
                            attributes);

                }, connections);
    }

    @PreDestroy
    protected void shutdown() throws Exception {
        UniversalConnectionPool universalConnectionPool = UniversalConnectionPoolManagerImpl
                .getUniversalConnectionPoolManager()
                .getConnectionPool(this.connectionPool.unwrap(PoolDataSource.class).getConnectionPoolName());
        this.ucpTelemetry.unregisterMetrics(universalConnectionPool);
        if (this.additionMetrics != null) {
            this.additionMetrics.close();
        }
    }

}
