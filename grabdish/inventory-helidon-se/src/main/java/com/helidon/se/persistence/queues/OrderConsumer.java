/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.queues;

import com.helidon.se.persistence.Database;
import com.helidon.se.persistence.dao.InventoryDao;
import com.helidon.se.persistence.dao.model.InventoryMessage;
import com.helidon.se.persistence.dao.model.OrderMessage;
import com.helidon.se.util.JsonUtils;
import com.helidon.se.util.MetricUtils;

import io.helidon.config.Config;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class OrderConsumer implements AutoCloseable {

    private final Database database;
    private final InventoryDao dao;
    private final String queueOwner;
    private final String orderQueue;
    private final String invQueue;
    private QueueConsumer consumer;

    public OrderConsumer(Database database, Config config) {
        this.database = database;
        this.dao = new InventoryDao();
        this.queueOwner = config.get("db.queueOwner").asString().get();
        this.orderQueue = config.get("db.orderQueueName").asString().get();
        this.invQueue = config.get("db.inventoryQueueName").asString().get();
    }

    public void start() throws Exception {
        this.consumer = new QueueConsumer(database, queueOwner, orderQueue, MetricUtils.ordQConsumer,
                (context, message) -> {
                    OrderMessage order = JsonUtils.read(message, OrderMessage.class);
                    context.execute(conn -> {
                        String location = dao.decrement(conn, order.getItemid());
                        context.sendMessage(
                                new InventoryMessage(order.getOrderid(), order.getItemid(), location, "beer"),
                                queueOwner, invQueue);
                        conn.commit();
                        return null;
                    });
                }, log);
        consumer.start();
    }

    @Override
    public void close() throws InterruptedException {
        consumer.close();
    }
}
