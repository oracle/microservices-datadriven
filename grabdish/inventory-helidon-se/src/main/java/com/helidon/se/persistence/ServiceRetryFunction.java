/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence;

import java.io.InterruptedIOException;
import java.sql.SQLException;
import java.util.Objects;
import java.util.function.BiFunction;

import com.helidon.se.persistence.queues.QueueConsumer;

import io.helidon.config.Config;
import oracle.ucp.UniversalConnectionPoolException;

public class ServiceRetryFunction implements BiFunction<Throwable, Integer, Long> {

    private final int retryCount;
    private final long retryPeriod;
    private final int shutdownRetryCount;
    private final long shutdownRetryPeriod;

    public ServiceRetryFunction(Config dbConfig) {
        this.retryCount = dbConfig.get("retryCount").asInt().orElse(0);
        this.retryPeriod = dbConfig.get("retryPeriod").asLong().orElse(0L);
        this.shutdownRetryCount = dbConfig.get("shutdownRetryCount").asInt().orElse(1);
        this.shutdownRetryPeriod = dbConfig.get("shutdownRetryPeriod").asLong().orElse(1000L);
    }

    // ORA-12514 depth
    // SQLException ->
    // UniversalConnectionPoolException ->
    // SQLRecoverableException(vendorCode = 12514) ->
    // NetException(errorNumber = 12514)

    @Override
    public Long apply(Throwable e, Integer count) {
        if (count < retryCount || count < shutdownRetryCount) {
            // soda exception
            if (e instanceof SQLException || e instanceof UniversalConnectionPoolException) {
                // unwrap SQLException from all others like soda, UCP, etc..
                // seems like the last sqk always meaningful
                SQLException sql = getLastSqlException(e);
                if (Objects.nonNull(sql)) {
                    return handleSQLException(sql, count);
                } else {
                    return count < retryCount ? retryPeriod : null;
                }
            }
        }
        return null;
    }

    public SQLException getLastSqlException(Throwable e) {
        SQLException last = null;
        while (Objects.nonNull(e)) {
            if (e instanceof SQLException) {
                last = (SQLException) e;
            }
            e = e.getCause();
        }
        return last;
    }

    @SuppressWarnings("DanglingJavadoc")
    private Long handleSQLException(SQLException e, Integer count) {
        switch (e.getErrorCode()) {
            case 1: //java.sql.SQLIntegrityConstraintViolationException: ORA-00001: unique constraint (JAVA_ORDERS.SYS_C007825) violated
                return null;
            case 17002: // when consumer is shutting down java.sql.SQLRecoverableException: IO Error: Socket read interrupted
                /**
                 * thread was interrupted while consumer shutdown
                 * see {@link QueueConsumer#close()}
                 */
                if (e.getCause() instanceof InterruptedIOException) {
                    return null;
                }
                break;
            case 12514: // after database node down java.sql.SQLRecoverableException: Listener refused the connection with the following error:
                // ORA-12514, TNS:listener does not currently know of service requested in connect descriptor
            case 12757:
            case 12541:
            case 17410: // when database node going down java.sql.SQLRecoverableException: No more data to read from socket
            case 1109: // when pdb is closed java.sql.SQLException: ORA-01109: database not open
                return count < shutdownRetryCount ? shutdownRetryPeriod : null;
            default:
        }
        return count < retryCount ? retryPeriod : null;
    }
}
