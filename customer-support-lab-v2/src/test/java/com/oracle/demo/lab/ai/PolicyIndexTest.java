// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

import com.oracle.demo.lab.messaging.OKafkaManager;
import com.oracle.demo.lab.messaging.TicketEventConsumer;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.common.KafkaFuture;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.jdbc.core.simple.JdbcClient;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class PolicyIndexTest {
    private final DataSource dataSource = mock(DataSource.class);
    private final Connection connection = mock(Connection.class);
    private final PreparedStatement statement = mock(PreparedStatement.class);
    private final ResultSet result = mock(ResultSet.class);
    private final EmbeddingModel model = mock(EmbeddingModel.class);
    private final AsyncTaskExecutor executor = mock(AsyncTaskExecutor.class);
    private final Admin admin = mock(Admin.class);
    private final TicketEventConsumer consumer = mock(TicketEventConsumer.class);

    @BeforeEach
    void prepareDatabaseAndTopic() throws Exception {
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.prepareStatement(anyString())).thenReturn(statement);
        when(connection.getAutoCommit()).thenReturn(true);
        when(statement.executeQuery()).thenReturn(result);
        when(result.getString("policy_id")).thenReturn("MFA_RECOVERY");
        when(result.getString("title")).thenReturn("MFA recovery");
        when(result.getString("body")).thenReturn("Verify identity.");
        ListTopicsResult topics = mock(ListTopicsResult.class);
        when(admin.listTopics()).thenReturn(topics);
        when(topics.names()).thenReturn(KafkaFuture.completedFuture(Set.of("TICKET_EVENT")));
    }

    @Test
    void aiStartupCommitsMissingEmbeddingsBeforeStartingConsumer() throws Exception {
        when(result.next()).thenReturn(true, false);
        when(model.embed(List.of("MFA recovery\nVerify identity.")))
                .thenReturn(List.of(new float[1536]));

        try (ConfigurableApplicationContext ignored = start()) {
            var calls = inOrder(model, connection, executor);
            calls.verify(model).embed(List.of("MFA recovery\nVerify identity."));
            calls.verify(connection).commit();
            calls.verify(executor).submit(consumer);
        }
    }

    @Test
    void existingEmbeddingsSkipEmbeddingServiceAtStartup() {
        try (ConfigurableApplicationContext ignored = start()) {
            verifyNoInteractions(model);
        }
    }

    @Test
    void invalidEmbeddingsFailStartupBeforeConsumerStarts() throws Exception {
        when(result.next()).thenReturn(true, false);
        when(model.embed(List.of("MFA recovery\nVerify identity.")))
                .thenReturn(List.of(new float[1024]));

        assertThrows(IllegalStateException.class, () -> start());

        verifyNoInteractions(executor);
    }

    private ConfigurableApplicationContext start() {
        return new SpringApplicationBuilder(StartupConfiguration.class)
                .web(WebApplicationType.NONE)
                .properties("spring.config.name=policy-index-test", "spring.main.banner-mode=off",
                        "okafka.topic.tickets=TICKET_EVENT")
                .initializers(context -> {
                    var beans = context.getBeanFactory();
                    beans.registerSingleton("dataSource", dataSource);
                    beans.registerSingleton("jdbcClient", JdbcClient.create(dataSource));
                    beans.registerSingleton("embeddingModel", model);
                    beans.registerSingleton("applicationTaskExecutor", executor);
                    beans.registerSingleton("admin", admin);
                    beans.registerSingleton("eventConsumer", consumer);
                })
                .run();
    }

    @Configuration(proxyBeanMethods = false)
    @Import({PolicyIndex.class, OKafkaManager.class})
    static class StartupConfiguration {
    }
}
