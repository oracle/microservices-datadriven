/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence;

import java.sql.SQLException;
import java.util.Objects;

import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.Timer;
import org.slf4j.Logger;

import com.helidon.se.persistence.context.DBContext;
import com.helidon.se.persistence.context.OracleJmsDBContext;
import com.helidon.se.util.MetricUtils;

import io.helidon.config.Config;
import io.helidon.metrics.RegistryFactory;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Slf4j
@Getter
public class Database {

    private final PoolDataSource dataSource;
    private final Config dbConfig;
    private final ServiceRetryFunction retry;
    private final Timer acquire;

    public Database(Config config) throws SQLException {
        this.dbConfig = config.get("db");
        this.retry = new ServiceRetryFunction(dbConfig);
        // create pool
        dataSource = PoolDataSourceFactory.getPoolDataSource();
        dataSource.setConnectionFactoryClassName(dbConfig.get("class").asString().get());
        String user = dbConfig.get("user").asString().get();
        dataSource.setUser(user);
        dataSource.setPassword(dbConfig.get("password").asString().get());
        String url = dbConfig.get("url").asString().get();
        dataSource.setURL(url);
        Boolean boolParam = dbConfig.get("failoverEnabled").asBoolean().orElseGet(() -> null);
        if (Objects.nonNull(boolParam)) {
            dataSource.setFastConnectionFailoverEnabled(boolParam);
        }
        Integer intParam = dbConfig.get("initialPoolSize").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setInitialPoolSize(intParam);
        }
        intParam = dbConfig.get("minPoolSize").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setMinPoolSize(intParam);
        }
        intParam = dbConfig.get("maxPoolSize").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setMaxPoolSize(intParam);
        }
        intParam = dbConfig.get("timeoutCheckInterval").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setTimeoutCheckInterval(intParam);
        }
        intParam = dbConfig.get("inactiveConnectionTimeout").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setInactiveConnectionTimeout(intParam);
        }
        intParam = dbConfig.get("queryTimeout").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setQueryTimeout(intParam);
        }
        intParam = dbConfig.get("connectionWaitTimeout").asInt().orElseGet(() -> null);
        if (Objects.nonNull(intParam)) {
            dataSource.setConnectionWaitTimeout(intParam);
        }
        // test connection
        dataSource.getConnection().close();
        log.info("Database connected {} user:{}", url, user);
        RegistryFactory metricsRegistry = RegistryFactory.getInstance();
        MetricRegistry appRegistry = metricsRegistry.getRegistry(MetricRegistry.Type.APPLICATION);
        acquire = appRegistry.timer(MetricUtils.acquire);
    }

    public OracleConnection getConnection() throws SQLException {
        Timer.Context timerContext = acquire.time();
        OracleConnection conn = (OracleConnection) getDataSource().getConnection();
        timerContext.stop();
        return conn;
    }

    public DBContext getContext(Logger log) throws Exception {
        return new OracleJmsDBContext(this, retry, log);
    }

}
