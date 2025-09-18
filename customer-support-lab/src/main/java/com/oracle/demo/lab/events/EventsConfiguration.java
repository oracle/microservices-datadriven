package com.oracle.demo.lab.events;

import java.util.Properties;

import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.spring.json.kafka.OSONKafkaSerializationFactory;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.common.serialization.Deserializer;
import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.oracle.okafka.clients.admin.AdminClient;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("events")
public class EventsConfiguration {
    @Value("${okafka.walletDir}")
    private String walletDir;

    @Value("${okafka.bootstrapServers:localhost:1521}")
    private String bootstrapServers;

    // We use the default 23ai Free service name
    @Value("${okafka.tnsAdmin}")
    private String tnsAdmin;

    // "SSL" for wallet connections, like Autonomous Database.
    @Value("${okafka.securityProtocol:SSL}")
    private String securityProtocol;

    @Bean
    @Qualifier("okafkaAuth")
    public Properties okafkaAuth() {
        // Just like kafka-clients, we can use a Java Properties object to configure connection parameters.
        Properties props = new Properties();

        // oracle.service.name is a custom property to configure the Database service name.
        props.put("oracle.service.name", tnsAdmin);
        // oracle.net.tns_admin is a custom property to configure the directory containing Oracle Database connection files.
        // If you are using mTLS authentication, client certificates must be present in this directory.
        props.put("oracle.net.tns_admin", walletDir);
        // security.protocol is a standard Kafka property, set to PLAINTEXT or SSL for Oracle Database.
        // (SASL is not supported with Oracle Database).
        props.put("security.protocol", securityProtocol);
        if (securityProtocol.equals("SSL")) {
            // For SSL authentication, pass the TNS alias (such as "mydb_tp") to be used from the tnsnames.ora file
            // found in the WALLET_DIR directory.
            props.put("tns.alias", tnsAdmin);
        } else {
            // For PLAINTEXT authentication, we provide the database URL in the format
            // HOSTNAME:PORT as the bootstrap.servers property.
            props.put("bootstrap.servers", bootstrapServers);
        }
        return props;
    }

    @Bean
    public Admin adminClient() {
        return AdminClient.create(okafkaAuth());
    }

    @Bean
    public KafkaProducer<String, SupportTicket> ticketProducer(OSONKafkaSerializationFactory serializationFactory) {
        Properties props = okafkaAuth();
        props.put("enable.idempotence", "true");
        // This property is required for transactional producers
        props.put("oracle.transactional.producer", "true");

        Serializer<String> keySerializer = new StringSerializer();
        Serializer<SupportTicket> valueSerializer = serializationFactory.createSerializer();
        // Note the use of the org.oracle.okafka.clients.producer.KafkaProducer class
        // for producing records to Oracle Database Transactional Event Queues.
        KafkaProducer<String, SupportTicket> producer = new KafkaProducer<>(props, keySerializer, valueSerializer);
        // Initialize the producer for transactional workflows.
        producer.initTransactions();
        return producer;
    }

    @Bean
    public KafkaConsumer<String, SupportTicket> ticketConsumer(OSONKafkaSerializationFactory serializationFactory) {
        Properties props = okafkaAuth();
        // Note the use of standard Kafka properties for OKafka configuration.
        props.put("group.id" , "TICKETS");
        props.put("enable.auto.commit","false");
        props.put("max.poll.records", 50);
        props.put("auto.offset.reset", "earliest");

        Deserializer<String> keyDeserializer = new StringDeserializer();
        Deserializer<SupportTicket> valueDeserializer = serializationFactory.createDeserializer(SupportTicket.class);
        return new KafkaConsumer<>(props, keyDeserializer, valueDeserializer);
    }
}
