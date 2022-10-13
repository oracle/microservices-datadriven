/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.config.data;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * TODO: Adjust documentation
 * Wrapper for {@link org.apache.kafka.streams.StreamsBuilder} properties.
 *
 * @author Paulo Simoes
 * @since 1.0
 *
 */
@Configuration
@ConfigurationProperties(prefix = "okafka-topic-config")
public class OKafkaTopicConfigData {
    private String topicName;
    private Integer numOfPartitions = 3;
    private Short replicationFactor = 1;


    public OKafkaTopicConfigData() {}

    public OKafkaTopicConfigData(String topicName) {
        this.topicName = topicName;
    }

    public OKafkaTopicConfigData(String topicName, Integer numOfPartitions, Short replicationFactor) {
        this.topicName = topicName;
        this.numOfPartitions = numOfPartitions;
        this.replicationFactor = replicationFactor;
    }

    public String getTopicName() {
        return topicName;
    }

    public void setTopicName(String topicName) {
        this.topicName = topicName;
    }

    public Integer getNumOfPartitions() {
        return numOfPartitions;
    }

    public void setNumOfPartitions(Integer numOfPartitions) {
        this.numOfPartitions = numOfPartitions;
    }

    public Short getReplicationFactor() {
        return replicationFactor;
    }

    public void setReplicationFactor(Short replicationFactor) {
        this.replicationFactor = replicationFactor;
    }
}
