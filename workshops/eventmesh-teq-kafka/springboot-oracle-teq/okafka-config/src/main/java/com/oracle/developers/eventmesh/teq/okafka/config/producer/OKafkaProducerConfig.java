package com.oracle.developers.eventmesh.teq.okafka.config.producer;

import com.oracle.developers.eventmesh.teq.okafka.config.data.OKafkaConfigData;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.oracle.okafka.clients.producer.ProducerConfig;
import org.oracle.okafka.common.config.SslConfigs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class OKafkaProducerConfig<K extends Serializable, V extends Serializable> {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaProducerConfig.class);

    private final OKafkaConfigData configData;
    private final OKafkaProducerConfigData producerConfigData;

    public OKafkaProducerConfig(OKafkaConfigData configData, OKafkaProducerConfigData producerConfigData) {
        this.configData = configData;
        this.producerConfigData = producerConfigData;
    }

    @Bean
    public Map<String, Object> producerConfig() {

        Map<String, Object> props = new HashMap<>();

        props.put(ProducerConfig.ORACLE_INSTANCE_NAME, configData.getOracleInstanceName());
        props.put(ProducerConfig.ORACLE_SERVICE_NAME, configData.getOracleServiceName());
        props.put(ProducerConfig.ORACLE_NET_TNS_ADMIN, configData.getOracleNetTns_admin());
        props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, configData.getSecurityProtocol());
        props.put(CommonClientConfigs.ORACLE_USER_NAME, configData.getOracleUserName());
        props.put(CommonClientConfigs.ORACLE_PASSWORD, configData.getOraclePassword());
        props.put(SslConfigs.TNS_ALIAS, configData.getTnsAlias());

        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, configData.getBootstrapServers());
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, producerConfigData.getKeySerializerClass());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, producerConfigData.getValueSerializerClass());
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, producerConfigData.getBatchSize() *
                producerConfigData.getBatchSizeBoostFactor());
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, producerConfigData.getBufferMemory());
        props.put(ProducerConfig.LINGER_MS_CONFIG, producerConfigData.getLingerMs());

        //props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, teqProducerConfigData.getCompressionType());
        //props.put(ProducerConfig.ACKS_CONFIG, teqProducerConfigData.getAcks());
        //props.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, teqProducerConfigData.getRequestTimeoutMs());
        //props.put(ProducerConfig.RETRIES_CONFIG, teqProducerConfigData.getRetryCount());

        LOG.info("OKafkaProducerConfig started and Oracle Instance is {}.", configData.getOracleInstanceName());
        return props;
    }



    @Bean
    public KafkaProducer<K, V> producerFactory() {
        return new KafkaProducer<>(producerConfig());
    }

}
