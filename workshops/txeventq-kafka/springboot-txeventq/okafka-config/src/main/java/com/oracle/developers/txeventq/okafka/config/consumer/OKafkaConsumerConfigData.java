/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.config.consumer;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "okafka-consumer-config")
public class OKafkaConsumerConfigData {
    private String keyDeserializer;
    private String valueDeserializer;
    private String groupId;
    private Boolean enableAutoCommit;
    private Integer autoCommitIntervalMs;
    private Integer maxPollRecords;

    public OKafkaConsumerConfigData() {}

    public OKafkaConsumerConfigData(String keyDeserializer, String valueDeserializer, String groupId, Boolean enableAutoCommit, Integer autoCommitIntervalMs, Integer maxPollRecords) {
        this.keyDeserializer = keyDeserializer;
        this.valueDeserializer = valueDeserializer;
        this.groupId = groupId;
        this.enableAutoCommit = enableAutoCommit;
        this.autoCommitIntervalMs = autoCommitIntervalMs;
        this.maxPollRecords = maxPollRecords;
    }

    public String getKeyDeserializer() {
        return keyDeserializer;
    }

    public void setKeyDeserializer(String keyDeserializer) {
        this.keyDeserializer = keyDeserializer;
    }

    public String getValueDeserializer() {
        return valueDeserializer;
    }

    public void setValueDeserializer(String valueDeserializer) {
        this.valueDeserializer = valueDeserializer;
    }

    public String getGroupId() {
        return groupId;
    }

    public void setGroupId(String groupId) {
        this.groupId = groupId;
    }

    public Boolean getEnableAutoCommit() {
        return enableAutoCommit;
    }

    public void setEnableAutoCommit(Boolean enableAutoCommit) {
        this.enableAutoCommit = enableAutoCommit;
    }

    public Integer getAutoCommitIntervalMs() {
        return autoCommitIntervalMs;
    }

    public void setAutoCommitIntervalMs(Integer autoCommitIntervalMs) {
        this.autoCommitIntervalMs = autoCommitIntervalMs;
    }

    public Integer getMaxPollRecords() {
        return maxPollRecords;
    }

    public void setMaxPollRecords(Integer maxPollRecords) {
        this.maxPollRecords = maxPollRecords;
    }
}
