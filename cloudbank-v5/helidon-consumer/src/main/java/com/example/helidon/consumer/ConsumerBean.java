// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.example.helidon.consumer;

import io.opentelemetry.instrumentation.annotations.WithSpan;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.CompletionStage;

@ApplicationScoped
public class ConsumerBean {

    private static final Logger LOGGER = LoggerFactory.getLogger(ConsumerBean.class);

    @Incoming("from-kafka")
    @WithSpan
    public CompletionStage<Void> consume(Message<String> message) {
        LOGGER.info("Consumed message from Kafka: {}", message.getPayload());
        return message.ack();
    }
}
