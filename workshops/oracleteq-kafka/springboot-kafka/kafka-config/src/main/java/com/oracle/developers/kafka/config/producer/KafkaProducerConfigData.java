/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.kafka.config.producer;

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
@ConfigurationProperties(prefix = "kafka-producer-config")
public class KafkaProducerConfigData {
    private String keySerializerClass;
    private String valueSerializerClass;
    private String compressionType;
    private String acks;
    private Integer batchSize;
    private Integer batchSizeBoostFactor;
    private Integer lingerMs;
    private Integer requestTimeoutMs;
    private Integer retryCount;

    public KafkaProducerConfigData() {}

    public KafkaProducerConfigData(String keySerializerClass, String valueSerializerClass, String compressionType, String acks, Integer batchSize, Integer batchSizeBoostFactor, Integer lingerMs, Integer requestTimeoutMs, Integer retryCount) {
        this.keySerializerClass = keySerializerClass;
        this.valueSerializerClass = valueSerializerClass;
        this.compressionType = compressionType;
        this.acks = acks;
        this.batchSize = batchSize;
        this.batchSizeBoostFactor = batchSizeBoostFactor;
        this.lingerMs = lingerMs;
        this.requestTimeoutMs = requestTimeoutMs;
        this.retryCount = retryCount;
    }

    public String getKeySerializerClass() {
        return keySerializerClass;
    }

    public void setKeySerializerClass(String keySerializerClass) {
        this.keySerializerClass = keySerializerClass;
    }

    public String getValueSerializerClass() {
        return valueSerializerClass;
    }

    public void setValueSerializerClass(String valueSerializerClass) {
        this.valueSerializerClass = valueSerializerClass;
    }

    public String getCompressionType() {
        return compressionType;
    }

    public void setCompressionType(String compressionType) {
        this.compressionType = compressionType;
    }

    public String getAcks() {
        return acks;
    }

    public void setAcks(String acks) {
        this.acks = acks;
    }

    public Integer getBatchSize() {
        return batchSize;
    }

    public void setBatchSize(Integer batchSize) {
        this.batchSize = batchSize;
    }

    public Integer getBatchSizeBoostFactor() {
        return batchSizeBoostFactor;
    }

    public void setBatchSizeBoostFactor(Integer batchSizeBoostFactor) {
        this.batchSizeBoostFactor = batchSizeBoostFactor;
    }

    public Integer getLingerMs() {
        return lingerMs;
    }

    public void setLingerMs(Integer lingerMs) {
        this.lingerMs = lingerMs;
    }

    public Integer getRequestTimeoutMs() {
        return requestTimeoutMs;
    }

    public void setRequestTimeoutMs(Integer requestTimeoutMs) {
        this.requestTimeoutMs = requestTimeoutMs;
    }

    public Integer getRetryCount() {
        return retryCount;
    }

    public void setRetryCount(Integer retryCount) {
        this.retryCount = retryCount;
    }
}

