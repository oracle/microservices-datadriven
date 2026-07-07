// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.example.helidon.producer;

import jakarta.annotation.security.RolesAllowed;
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

import io.helidon.security.annotations.Authenticated;
import org.eclipse.microprofile.jwt.JsonWebToken;
import jakarta.inject.Inject;
import jakarta.json.JsonString;
import java.util.Collection;

@Path("/post")
@ApplicationScoped
@Authenticated
public class ProducerResource {

    @Inject
    private JsonWebToken jwt;

    private static final Logger LOGGER = LoggerFactory.getLogger(ProducerResource.class);

    @Inject
    @Channel("to-kafka")
    private Emitter<String> emitter;

    @POST
    @Consumes(MediaType.TEXT_PLAIN)
    @Produces(MediaType.APPLICATION_JSON)
    public Response postMessage(String messageText) {
        if (!hasAnyScope("cloudbank.internal")) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }

        LOGGER.info("Sending message to Kafka: {}", messageText);
        try {
            emitter.send(messageText);
            return Response.ok("{\"status\":\"Message sent to Kafka\"}").build();
        } catch (Exception e) {
            LOGGER.error("Failed to send message to Kafka", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"Failed to send message\"}")
                    .build();
        }
    }

    private boolean hasAnyScope(String... allowedScopes) {
        Object scopeClaim = jwt == null ? null : jwt.getClaim("scope");
        if (scopeClaim instanceof Collection<?> scopes) {
            for (Object scope : scopes) {
                if (matchesAny(normalizeScope(scope), allowedScopes)) {
                    return true;
                }
            }
        }
        if (scopeClaim instanceof String scopes) {
            for (String scope : scopes.split(" ")) {
                if (matchesAny(scope, allowedScopes)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static String normalizeScope(Object scope) {
        if (scope instanceof JsonString jsonString) {
            return jsonString.getString();
        }
        String value = String.valueOf(scope);
        if (value.length() > 1 && value.startsWith("\"") && value.endsWith("\"")) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }

    private static boolean matchesAny(String scope, String... allowedScopes) {
        for (String allowedScope : allowedScopes) {
            if (allowedScope.equals(scope)) {
                return true;
            }
        }
        return false;
    }
}
