/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.http.service;

import java.util.Objects;

import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.Timer;

import com.helidon.se.http.HttpStatusException;
import com.helidon.se.http.service.model.Inventory;
import com.helidon.se.persistence.Database;
import com.helidon.se.persistence.dao.InventoryDao;
import com.helidon.se.util.JsonUtils;
import com.helidon.se.util.MetricUtils;

import io.helidon.metrics.RegistryFactory;
import io.helidon.webserver.Routing;
import io.helidon.webserver.ServerRequest;
import io.helidon.webserver.ServerResponse;
import io.helidon.webserver.Service;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class InventoryService implements Service {

    protected final Database database;
    protected final InventoryDao dao;
    protected final Timer inventoryGet;
    protected final Counter errorInventoryGet;

    public InventoryService(Database database) {
        this.database = database;
        this.dao = new InventoryDao();
        RegistryFactory metricsRegistry = RegistryFactory.getInstance();
        MetricRegistry appRegistry = metricsRegistry.getRegistry(MetricRegistry.Type.APPLICATION);
        inventoryGet = appRegistry.timer(MetricUtils.getInventory);
        errorInventoryGet = appRegistry.counter(MetricUtils.getInventory + ":error");
    }

    @Override
    public void update(Routing.Rules rules) {
        rules.get("/{id}", this::get);
    }

    public void get(ServerRequest request, ServerResponse response) {
        // metrics support
        Timer.Context timerContext = inventoryGet.time();
        response.whenSent().thenAccept(res -> timerContext.stop());
        // db transaction
        try {
            Inventory retval = database.getContext(log).execute(conn -> {
                Inventory inventory = dao.get(conn, request.path().param("id"));
                conn.close();
                return inventory;
            });
            if (Objects.nonNull(retval)) {
                response.send(JsonUtils.writeValueAsString(retval));
            } else {
                throw new HttpStatusException(404, "Inventory not found.");
            }
        } catch (Exception e) {
            errorInventoryGet.inc();
            request.next(e);
        }
    }

}
