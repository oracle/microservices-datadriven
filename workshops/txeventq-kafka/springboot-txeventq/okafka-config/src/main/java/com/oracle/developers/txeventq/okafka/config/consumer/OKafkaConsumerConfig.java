/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.config.consumer;

import com.oracle.developers.txeventq.okafka.config.data.OKafkaConfigData;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.clients.consumer.ConsumerConfig;
import org.oracle.okafka.common.config.SslConfigs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class OKafkaConsumerConfig {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaConsumerConfig.class);

    private final OKafkaConfigData configData;
    private final OKafkaConsumerConfigData consumerConfigData;

    public OKafkaConsumerConfig(OKafkaConfigData configData, OKafkaConsumerConfigData consumerConfigData) {
        this.configData = configData;
        this.consumerConfigData = consumerConfigData;
    }

    @Bean
    public Map<String, Object> consumerConfig() {

        Map<String, Object> props = new HashMap<>();

//        props.put(CommonClientConfigs.ORACLE_USER_NAME, configData.getOracleUserName());
//        props.put(CommonClientConfigs.ORACLE_PASSWORD, configData.getOraclePassword());
        props.put(ConsumerConfig.ORACLE_INSTANCE_NAME, configData.getOracleInstanceName());
        props.put(ConsumerConfig.ORACLE_SERVICE_NAME, configData.getOracleServiceName());
        props.put(ConsumerConfig.ORACLE_NET_TNS_ADMIN, configData.getOracleNetTns_admin());
        props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, configData.getSecurityProtocol());
        props.put(SslConfigs.TNS_ALIAS, configData.getTnsAlias());

        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, configData.getBootstrapServers());
        props.put(ConsumerConfig.GROUP_ID_CONFIG, consumerConfigData.getGroupId());
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, consumerConfigData.getKeyDeserializer());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, consumerConfigData.getValueDeserializer());
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, consumerConfigData.getEnableAutoCommit());
        props.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, consumerConfigData.getAutoCommitIntervalMs());
        props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, consumerConfigData.getMaxPollRecords());

        LOG.info("OKafkaConsumerConfig::consumerConfig started and Oracle Instance is {}.", configData.getOracleInstanceName());
        return props;
    }
}
