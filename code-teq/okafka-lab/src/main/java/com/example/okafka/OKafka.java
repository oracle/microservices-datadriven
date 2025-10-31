package com.example.okafka;

public interface OKafka {
    String TOPIC_NAME = "test_topic";

    static String getEnv(String key, String defaultValue) {
        String value = System.getenv(key);
        if (value == null || value.isEmpty()) {
            return defaultValue;
        }
        return value;
    }
}
