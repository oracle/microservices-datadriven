// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.messaging;

import com.oracle.demo.lab.messaging.EventsConfiguration;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.observability.TicketTelemetry;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.persistence.TicketStore;
import com.oracle.spring.json.kafka.OSONKafkaSerializationFactory;
import org.junit.jupiter.api.Test;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

class EventsConfigurationTest {
    @Test
    void feedbackGetsANewTransactionalProducerFromTheSameConfiguration() throws Exception {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "SSL");
        ReflectionTestUtils.setField(configuration, "walletDir", "/tmp/lab-wallet");
        ReflectionTestUtils.setField(configuration, "tnsAdmin", "mydb_tp");
        OSONKafkaSerializationFactory serializers = mock(OSONKafkaSerializationFactory.class);
        List<Properties> properties = new ArrayList<>();
        try (var construction = mockConstruction(KafkaProducer.class,
                (producer, context) -> properties.add((Properties) context.arguments().getFirst()))) {
            var ticket = configuration.ticketProducer(serializers);
            var feedback = configuration.reviewProducer(serializers);

            assertNotSame(ticket, feedback);
            assertEquals(2, construction.constructed().size());
            assertNotSame(properties.get(0), properties.get(1));
            assertEquals(properties.get(0), properties.get(1));
            assertEquals("true", properties.getFirst().getProperty("oracle.transactional.producer"));
            verify(ticket).initTransactions();
            verify(feedback).initTransactions();
            verify(serializers, times(2)).createSerializer();
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void springInjectsEachProducerIntoItsOwnService() {
        KafkaProducer<String, TicketWorkEvent> ticket = mock(KafkaProducer.class);
        KafkaProducer<String, TicketWorkEvent> feedback = mock(KafkaProducer.class);
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().setActiveProfiles("events", "ai", "blockchain");
            var beans = context.getBeanFactory();
            beans.registerSingleton("ticketProducer", ticket);
            beans.registerSingleton("reviewProducer", feedback);
            beans.registerSingleton("ticketStore", mock(TicketStore.class));
            beans.registerSingleton("outcomeStore", mock(TicketEventOutcomeStore.class));
            beans.registerSingleton("approvals", mock(TicketApprovalStore.class));
            beans.registerSingleton("telemetry", mock(TicketTelemetry.class));
            context.register(TicketEventProducer.class, TicketReviewService.class);
            context.refresh();

            assertSame(ticket, ReflectionTestUtils.getField(context.getBean(TicketEventProducer.class), "producer"));
            assertSame(feedback, ReflectionTestUtils.getField(context.getBean(TicketReviewService.class), "producer"));
        }
    }

    @Test
    void unsupportedProtocolCannotSilentlySelectPlaintext() {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "SL");

        IllegalArgumentException error = assertThrows(IllegalArgumentException.class,
                configuration::okafkaAuth);

        assertEquals("OKAFKA_SECURITY_PROTOCOL must be SSL or PLAINTEXT", error.getMessage());
    }

    @Test
    void plaintextConnectionFileEnablesJdbcTracingForOkafkaConnections() throws Exception {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "PLAINTEXT");
        ReflectionTestUtils.setField(configuration, "bootstrapServers", "localhost:1522");
        ReflectionTestUtils.setField(configuration, "tnsAdmin", "FREEPDB1");
        ReflectionTestUtils.setField(configuration, "dbUsername", "LAB_USER");
        ReflectionTestUtils.setField(configuration, "dbPassword", "test-only-password");
        var properties = configuration.okafkaAuth();
        Path directory = Path.of(properties.getProperty("oracle.net.tns_admin"));
        Path file = directory.resolve("ojdbc.properties");
        try (var reader = Files.newBufferedReader(file)) {
            var jdbc = new Properties();
            jdbc.load(reader);
            assertEquals("open-telemetry-trace-event-listener-provider",
                    jdbc.getProperty("oracle.jdbc.provider.traceEventListener"));
            assertEquals("LAB_USER", jdbc.getProperty("user"));
            assertEquals("test-only-password", jdbc.getProperty("password"));
        } finally {
            Files.deleteIfExists(file);
            Files.deleteIfExists(directory);
        }
    }

    @Test
    void sslUsesWalletAndTnsAlias() throws Exception {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "SSL");
        ReflectionTestUtils.setField(configuration, "walletDir", "/tmp/lab-wallet");
        ReflectionTestUtils.setField(configuration, "tnsAdmin", "mydb_tp");

        Properties properties = configuration.okafkaAuth();

        assertEquals("SSL", properties.getProperty("security.protocol"));
        assertEquals("/tmp/lab-wallet", properties.getProperty("oracle.net.tns_admin"));
        assertEquals("mydb_tp", properties.getProperty("tns.alias"));
    }
}
