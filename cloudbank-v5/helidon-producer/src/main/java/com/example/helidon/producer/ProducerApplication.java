// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.example.helidon.producer;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.Initialized;
import jakarta.enterprise.event.Observes;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;
import org.slf4j.bridge.SLF4JBridgeHandler;

import org.eclipse.microprofile.auth.LoginConfig;

/**
 * Main entry point for the Helidon JAX-RS Application.
 * Configures the SLF4J logging bridge to ensure JUL logs are routed to Logback.
 */
@ApplicationScoped
@ApplicationPath("/")
@LoginConfig(authMethod = "MP-JWT")
public class ProducerApplication extends Application {

    public void init(@Observes @Initialized(ApplicationScoped.class) Object event) {
        // Remove existing JUL handlers
        SLF4JBridgeHandler.removeHandlersForRootLogger();

        // Install the SLF4J Bridge Handler
        SLF4JBridgeHandler.install();

        System.out.println("Initialized SLF4JBridgeHandler to route Java Util Logging to Logback for Producer.");
    }
}
