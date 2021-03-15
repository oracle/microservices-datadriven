/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import org.slf4j.LoggerFactory;
import org.slf4j.bridge.SLF4JBridgeHandler;

import com.helidon.se.http.InventoryApi;
import com.helidon.se.persistence.Database;
import com.helidon.se.persistence.queues.OrderConsumer;
import com.helidon.se.util.ConfigUtils;

import ch.qos.logback.classic.LoggerContext;
import io.helidon.config.Config;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class Main {

    static {
        // JUL to slf4j bridge for logging from io.helidon and oracle.ucp. See logback.xml
        SLF4JBridgeHandler.removeHandlersForRootLogger();
        SLF4JBridgeHandler.install();
    }

    private static final String version = "1.0.0";
    private static InventoryApi api;
    private static final List<OrderConsumer> ordersConsumers = new ArrayList<>();

    public static void main(String... args) {
        try {
            // ShutdownHook
            Runtime.getRuntime().addShutdownHook(new Thread(Main::shutdown));
            // ------------------ Deploy ------------------
            Config config = ConfigUtils.buildConfig(args);
            Database database = new Database(config);
            // deploy queue consumers
            deployConsumers(config, database);
            // deploy http server
            try {
                api = new InventoryApi(database, config);
                api.start().toCompletableFuture().get(60, TimeUnit.SECONDS);
            } catch (IllegalStateException e) {
                log.info("Api not running {}.", e.getMessage());
            }
            log.info("................... Helidon started [v{}] logLevel:{} ...................", version, ConfigUtils.getLogLevel(log));
        } catch (Throwable e) {
            log.error("Main thread error. ", e);
            shutdown();
        }
    }

    private static void deployConsumers(Config config, Database database) throws Exception {
        Integer consumers = config.get("app.consumers").asInt().orElse(1);
        for (int i = 0; i < consumers; i++) {
            OrderConsumer ordersConsumer = new OrderConsumer(database, config);
            ordersConsumer.start();
            ordersConsumers.add(ordersConsumer);
        }
    }

    public static void shutdown() {
        try {
            if (!ordersConsumers.isEmpty()) {
                ordersConsumers.forEach(e -> {
                    try {
                        e.close();
                    } catch (InterruptedException ex) {
                        ex.printStackTrace();
                    }
                });
            }
            if (Objects.nonNull(api)) {
                api.stop().toCompletableFuture().get(60, TimeUnit.SECONDS);
            }
        } catch (Exception e) {
            log.error("Shutdown error. ", e);
        }
        log.info("................... Helidon shutdown ...................");
        ((LoggerContext) LoggerFactory.getILoggerFactory()).stop();
    }

}
