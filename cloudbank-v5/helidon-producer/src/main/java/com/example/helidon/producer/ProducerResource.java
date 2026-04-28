// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.example.helidon.producer;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path("/post")
@ApplicationScoped
public class ProducerResource {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProducerResource.class);

    @Inject
    @Channel("to-kafka")
    private Emitter<String> emitter;

    @POST
    @Consumes(MediaType.TEXT_PLAIN)
    @Produces(MediaType.APPLICATION_JSON)
    public Response postMessage(String message) {
        LOGGER.info("Sending message to Kafka: {}", message);
        try {
            emitter.send(message);
            return Response.ok("{\"status\":\"Message sent to Kafka\"}").build();
        } catch (Exception e) {
            LOGGER.error("Failed to send message to Kafka", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"" + e.getMessage() + "\"}")
                    .build();
        }
    }
}
