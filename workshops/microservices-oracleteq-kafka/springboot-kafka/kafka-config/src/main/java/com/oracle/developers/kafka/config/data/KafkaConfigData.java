/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.kafka.config.data;

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
@ConfigurationProperties(prefix = "kafka-server-config")
public class KafkaConfigData {
    private String bootstrapServers;
    private String schemaRegistryUrlKey;
    private String schemaRegistryUrl;

    public KafkaConfigData() {}

    public KafkaConfigData(String bootstrapServers, String schemaRegistryUrlKey, String schemaRegistryUrl) {
        this.bootstrapServers = bootstrapServers;
        this.schemaRegistryUrlKey = schemaRegistryUrlKey;
        this.schemaRegistryUrl = schemaRegistryUrl;
    }

    public String getBootstrapServers() {
        return bootstrapServers;
    }

    public void setBootstrapServers(String bootstrapServers) {
        this.bootstrapServers = bootstrapServers;
    }

    public String getSchemaRegistryUrlKey() {
        return schemaRegistryUrlKey;
    }

    public void setSchemaRegistryUrlKey(String schemaRegistryUrlKey) {
        this.schemaRegistryUrlKey = schemaRegistryUrlKey;
    }

    public String getSchemaRegistryUrl() {
        return schemaRegistryUrl;
    }

    public void setSchemaRegistryUrl(String schemaRegistryUrl) {
        this.schemaRegistryUrl = schemaRegistryUrl;
    }

}
