/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.logging.LogManager;

import io.helidon.data.examples.service.SupplierService;

import io.helidon.config.Config;
import io.helidon.media.jsonp.server.JsonSupport;
import io.helidon.webserver.Routing;
import io.helidon.webserver.ServerConfiguration;
import io.helidon.webserver.WebServer;

public final class Main {

  public static void main(final String[] args)
      throws IOException, SQLException {
    System.setProperty("oracle.jdbc.fanEnabled", "false");
    try (InputStream resourceAsStream = Main.class.getResourceAsStream("/logging.properties")) {
    LogManager
            .getLogManager()
            .readConfiguration(
                    resourceAsStream);
  }
    Config config = Config.create();
    ServerConfiguration serverConfig = ServerConfiguration
        .create(config.get("server"));
    WebServer server = WebServer.create(serverConfig, createRouting(config));
    server.start().thenAccept(ws -> {
        System.out
          .printf("webserver is up! http://localhost:%s/supplier%n", ws.port());
          ws.whenShutdown()
          .thenRun(() -> System.out.println("WEB server is DOWN. Good bye!"));
      }).exceptionally(t -> {
          System.err.printf("Startup failed: %s%n", t.getMessage());
          t.printStackTrace(System.err);
      return null;
      }
    );
  }

  private static Routing createRouting(Config config) throws SQLException {

    // Creates a Helidon's Service implementation.
    // Use database configuration from application.yaml that
    // can be over-ridden by System.properties
    SupplierService rsiService = new SupplierService(config.get("database"));

    // Create routing and register
    return Routing
        .builder()
        .register(JsonSupport.create())
        .register("/", rsiService)
        .build();
  }
}