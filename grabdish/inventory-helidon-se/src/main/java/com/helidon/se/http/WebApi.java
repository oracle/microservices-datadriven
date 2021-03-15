/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.http;

import java.sql.SQLException;
import java.util.Objects;
import java.util.concurrent.CompletionStage;
import java.util.function.Consumer;

import io.helidon.config.Config;
import io.helidon.health.HealthSupport;
import io.helidon.media.jsonp.server.JsonSupport;
import io.helidon.metrics.MetricsSupport;
import io.helidon.webserver.ErrorHandler;
import io.helidon.webserver.Routing;
import io.helidon.webserver.ServerConfiguration;
import io.helidon.webserver.WebServer;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class WebApi {

    protected final Config config;
    protected final ServerConfiguration serverConfig;
    protected final WebServer server;

    public WebApi(Config config, Consumer<Routing.Builder> addServices) {
        this.config = config;
        this.serverConfig = ServerConfiguration.create(config.get("server"));
        this.server = WebServer.create(serverConfig, createRouting(addServices));
    }

    public CompletionStage<WebServer> start() {
        return server.start().thenApply(e -> {
            log.info("Helidon WEB server started on port:{}", e.port());
            e.whenShutdown().thenRun(() -> log.info("Helidon WEB server shutdown"));
            return e;
        });
    }

    public CompletionStage<WebServer> stop() {
        return server.shutdown();
    }

    private Routing createRouting(Consumer<Routing.Builder> addServices) {
        // Health at "/health"
        // Metrics at "/metrics"
        Routing.Builder routings = Routing.builder()
                .any((req, resp) -> {
                    log.trace("[{}:{}]", req.method(), req.uri());
                    req.next();
                })
                .register(JsonSupport.create())
                .register(MetricsSupport.create())
                .register(HealthSupport.builder().addReadiness().addLiveness().build())
                .error(Throwable.class, handleErrors());
        // init services
        if (Objects.nonNull(addServices)) {
            addServices.accept(routings);
        }
        return routings.build();
    }

    private static ErrorHandler<Throwable> handleErrors() {
        return (req, res, t) -> {
            if (t instanceof HttpStatusException) {
                HttpStatusException ex = (HttpStatusException) t;
                res.status(ex.getStatus()).send(ex.getMessage());
            } else if (t instanceof SQLException) {
                // no stack trace for SQLException
                log.error("Error {}. [{}]{}", req.uri(), t.getClass().getName(), t.getMessage());
                res.status(500).send(t.getMessage());
            } else if (t instanceof Exception) {
                log.error("Error {}. ", req.uri(), t);
                res.status(500).send(t.getMessage());
            } else {
                log.error("Error {}. ", req.uri(), t);
                req.next(t);
            }
        };
    }
}
