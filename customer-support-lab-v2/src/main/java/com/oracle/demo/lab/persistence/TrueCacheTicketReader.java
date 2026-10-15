// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import com.oracle.demo.lab.model.SupportTicket;

import jakarta.annotation.PreDestroy;
import oracle.ucp.UniversalConnectionPoolException;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLRecoverableException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** A physically separate, read-only pool. No workflow writes use this connection. */
@Component
public class TrueCacheTicketReader {
    private static final Logger log = LoggerFactory.getLogger(TrueCacheTicketReader.class);
    private static final String POOL_NAME = "TrueCacheReadPool";
    private final PoolDataSource pool;
    private final String expectedDbUniqueName;

    public TrueCacheTicketReader(
            @Value("${app.true-cache.jdbc-url}") String url,
            @Value("${app.true-cache.username}") String username,
            @Value("${app.true-cache.password}") String password,
            @Value("${app.true-cache.db-unique-name}") String expectedDbUniqueName,
            @Value("${app.true-cache.max-pool-size:8}") int maxPoolSize) throws SQLException {
        if (maxPoolSize < 1) {
            throw new IllegalArgumentException("True Cache max pool size must be at least 1");
        }
        if (expectedDbUniqueName == null || expectedDbUniqueName.isBlank()) {
            throw new IllegalArgumentException("True Cache DB_UNIQUE_NAME must not be blank");
        }
        this.expectedDbUniqueName = expectedDbUniqueName;
        this.pool = PoolDataSourceFactory.getPoolDataSource();
        pool.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        pool.setConnectionPoolName(POOL_NAME);
        pool.setURL(url);
        pool.setUser(username);
        pool.setPassword(password);
        pool.setInitialPoolSize(0);
        pool.setMinPoolSize(0);
        pool.setMaxPoolSize(maxPoolSize);
        pool.setConnectionWaitTimeout(3);
        pool.setValidateConnectionOnBorrow(true);
    }

    public List<SupportTicket> getAllTickets() {
        try (Connection connection = openReadOnly();
             PreparedStatement statement = connection.prepareStatement(
                     "select id, title, description, review_feedback, workflow_status from support_ticket");
             ResultSet rows = statement.executeQuery()) {
            List<SupportTicket> tickets = new ArrayList<>();
            while (rows.next()) {
                tickets.add(new SupportTicket(rows));
            }
            return tickets;
        } catch (SQLException error) {
            throw classify(error);
        }
    }

    public Optional<SupportTicket> findById(long id) {
        try (Connection connection = openReadOnly();
             PreparedStatement statement = connection.prepareStatement(
                     "select id, title, description, review_feedback, workflow_status from support_ticket where id = ?")) {
            statement.setLong(1, id);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? Optional.of(new SupportTicket(rows)) : Optional.empty();
            }
        } catch (SQLException error) {
            throw classify(error);
        }
    }

    private Connection openReadOnly() {
        try {
            Connection connection = pool.getConnection();
            try {
                connection.setReadOnly(true);
                verifyCacheIdentity(connection, expectedDbUniqueName);
                return connection;
            } catch (SQLException error) {
                connection.close();
                throw error;
            }
        } catch (SQLException error) {
            throw new CacheUnavailableException("True Cache connection unavailable", error);
        }
    }

    static void verifyCacheIdentity(Connection connection, String expectedDbUniqueName) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "select sys_context('USERENV', 'DB_UNIQUE_NAME') from dual");
             ResultSet row = statement.executeQuery()) {
            String actual = row.next() ? row.getString(1) : null;
            if (!expectedDbUniqueName.equalsIgnoreCase(actual)) {
                throw new SQLException("Expected True Cache DB_UNIQUE_NAME " + expectedDbUniqueName
                        + " but connected to " + actual);
            }
        }
    }

    private static RuntimeException classify(SQLException error) {
        if (error instanceof SQLRecoverableException ||
                (error.getSQLState() != null && error.getSQLState().startsWith("08"))) {
            return new CacheUnavailableException("True Cache connection lost", error);
        }
        return new IllegalStateException("True Cache read failed", error);
    }

    @PreDestroy
    public void close() {
        try {
            UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager()
                    .destroyConnectionPool(POOL_NAME);
        } catch (UniversalConnectionPoolException error) {
            log.debug("True Cache pool was not active at shutdown ({})", error.getClass().getSimpleName());
        }
    }

    public static final class CacheUnavailableException extends RuntimeException {
        CacheUnavailableException(String message, SQLException cause) {
            super(message, cause);
        }
    }
}
