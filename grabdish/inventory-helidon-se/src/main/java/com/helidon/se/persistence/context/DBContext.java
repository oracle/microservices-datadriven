/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.context;

import java.util.Objects;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BiFunction;

import org.slf4j.Logger;

import com.helidon.se.persistence.Database;
import com.helidon.se.persistence.queues.QueueProvider;

import oracle.jdbc.OracleConnection;

// This instance is not thread safe!!!
public abstract class DBContext implements QueueProvider {

    protected final Database db;
    protected final BiFunction<Throwable, Integer, Long> retryFunction;
    protected final Logger log;

    public DBContext(Database db, BiFunction<Throwable, Integer, Long> retryFunction, Logger log) {
        this.db = db;
        this.retryFunction = retryFunction;
        this.log = log;
    }

    public abstract OracleConnection getConnection() throws Exception;

    public abstract void close() throws Exception;

    public <T> T execute(DBAction<T> dbAction) throws Exception {
        AtomicInteger count = new AtomicInteger(0);
        Long sleep = null;
        do {
            // clean up sleep in case of retry
            OracleConnection connection = null;
            try {
                connection = getConnection();
                return dbAction.accept(connection);
            } catch (Exception e) {
                // rollback the transaction
                if (connection != null) {
                    connection.rollback();
                }
                // check for retry
                sleep = retry(e, count, log);
            }
        } while (Objects.nonNull(sleep));
        return null;
    }

    private Long retry(Exception e, AtomicInteger count, Logger log) throws Exception {
        Long sleep = retryFunction.apply(e, count.getAndIncrement());
        if (Objects.nonNull(sleep)) {
            // log exception just on retry
            if (log.isDebugEnabled()) {
                log.error("Retry {}. Db exception. ", count, e);
            } else {
                // no stack trace if there is no debug mode
                log.error("Retry {}. Db exception. [{}]{}", count, e.getClass().getName(), e.getMessage());
            }
            if (sleep > 0) {
                try {
                    Thread.sleep(sleep);
                } catch (InterruptedException ex) {
                    log.error("Thread exception. ", ex);
                }
            }
        } else {
            // fail
            throw e;
        }
        return sleep;
    }

}
