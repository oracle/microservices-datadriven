/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.queues;

import java.io.InterruptedIOException;
import java.sql.SQLException;
import java.sql.SQLRecoverableException;
import java.util.Objects;

import javax.jms.JMSException;

import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.Timer;
import org.slf4j.Logger;

import com.helidon.se.persistence.Database;
import com.helidon.se.persistence.context.DBContext;

import io.helidon.metrics.RegistryFactory;
import oracle.jms.AQjmsException;

public class QueueConsumer implements AutoCloseable {

    private final long SLEEP_ON_ERROR = 1000L;

    protected final Database database;
    protected final String queueOwner;
    protected final String queueName;
    protected final MessageConsumer consumer;
    protected final Logger log;
    protected final Timer metric;
    protected final Counter errorMetric;
    private DBContext context;
    private Thread thread;
    private boolean running;

    public QueueConsumer(Database database, String queueOwner, String queueName, String metricName, MessageConsumer consumer, Logger log) {
        this.database = database;
        this.queueOwner = queueOwner;
        this.queueName = queueName;
        this.consumer = consumer;
        this.log = log;
        RegistryFactory metricsRegistry = RegistryFactory.getInstance();
        MetricRegistry appRegistry = metricsRegistry.getRegistry(MetricRegistry.Type.APPLICATION);
        metric = appRegistry.timer(metricName);
        errorMetric = appRegistry.counter(metricName + ":error");
    }

    public void start() throws Exception {
        this.running = true;
        this.context = database.getContext(log);
        this.thread = new Thread(() -> {
            try {
                while (running) {
                    try {
                        log.trace("Get message from {}:{}", queueOwner, queueName);
                        String message = context.getMessage(queueOwner, queueName);
                        if (message != null) {
                            try (Timer.Context ignored = metric.time()) {
                                consumer.accept(context, message);
                            }
                        }
                    } catch (JMSException e) {
                        if (Objects.nonNull(e.getCause())) {
                            if (e.getCause() instanceof SQLException) {
                                throw (SQLException) e.getCause();
                            }
                        }
                        errorMetric.inc();
                        if (log.isDebugEnabled()) {
                            log.error("Consumer jms error. ", e);
                        } else {
                            // no stack trace if there is no debug mode
                            log.error("Consumer jms error. [{}]{}", e.getClass().getName(), e.getMessage());
                        }
                        Thread.sleep(SLEEP_ON_ERROR); // sleep in case of error, before retry
                    } catch (SQLException e) {
                        if (Objects.nonNull(e.getCause())) {
                            // thread was interrupted while consumer shutdown see {@link QueueConsumer#close()}
                            if (e.getCause() instanceof InterruptedIOException) {
                                throw e;
                            }
                        }
                        errorMetric.inc();
                        if (log.isDebugEnabled()) {
                            log.error("Consumer sql error. ", e);
                        } else {
                            // no stack trace if there is no debug mode
                            log.error("Consumer sql error. [{}]{}", e.getClass().getName(), e.getMessage());
                        }
                        Thread.sleep(SLEEP_ON_ERROR); // sleep in case of error, before retry
                    }
                }
            } catch (SQLRecoverableException | AQjmsException e) {
                log.info("Connections interrupted and closed.");
            } catch (Exception e) {
                log.error("Consumer stop. ", e);
            }
        });
        thread.start();
        log.info("Listening for {}:{}", queueOwner, queueName);
    }

    @Override
    public void close() throws InterruptedException {
        this.running = false;
        this.thread.interrupt();
        this.thread.join();
        try {
            this.context.close();
        } catch (Exception e) {
            log.error("Close error. ", e);
        }
        log.info("Stop listening for {}", queueName);
    }

}
