// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.oracle.example;

import java.sql.SQLException;

import oracle.jdbc.pool.OracleDataSource;

final class TeqConfig {

    private static final String DEFAULT_USERNAME = "testuser";
    private static final String DEFAULT_URL = "jdbc:oracle:thin:@//localhost:1521/freepdb1";
    private static final String DEFAULT_TOPIC_NAME = "my_jms_teq";

    private final String username;
    private final String url;
    private final String password;
    private final String topicName;

    private TeqConfig(String username, String url, String password, String topicName) {
        this.username = username;
        this.url = url;
        this.password = password;
        this.topicName = topicName;
    }

    static TeqConfig fromEnvironment() {
        return new TeqConfig(
                envOrDefault("TEQ_DB_USER", DEFAULT_USERNAME),
                envOrDefault("TEQ_DB_URL", DEFAULT_URL),
                requiredEnv("TEQ_DB_PASSWORD"),
                envOrDefault("TEQ_TOPIC_NAME", DEFAULT_TOPIC_NAME));
    }

    OracleDataSource createDataSource() throws SQLException {
        OracleDataSource ds = new OracleDataSource();
        ds.setURL(url);
        ds.setUser(username);
        ds.setPassword(password);
        return ds;
    }

    String username() {
        return username;
    }

    String topicName() {
        return topicName;
    }

    private static String envOrDefault(String name, String defaultValue) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        return value;
    }

    private static String requiredEnv(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Environment variable " + name + " must be set.");
        }
        return value;
    }
}
