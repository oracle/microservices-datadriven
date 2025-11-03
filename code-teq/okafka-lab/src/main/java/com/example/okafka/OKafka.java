package com.example.okafka;

public interface OKafka {
    String TOPIC_NAME = "test_topic";

    String TRANSACTIONAL_TOPIC_NAME = "test_transactional_topic";

    static String getEnv(String key, String defaultValue) {
        String value = System.getenv(key);
        if (value == null || value.isEmpty()) {
            return defaultValue;
        }
        return value;
    }
}
