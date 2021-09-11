/*

 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package dblogexporter;

import java.sql.*;
import java.util.logging.FileHandler;
import java.util.logging.Logger;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import oracle.ucp.jdbc.PoolDataSource;

@Path("/")
@ApplicationScoped
public class DBLogExporterResource {

    @Inject
    @Named("alertlogpdb")
    PoolDataSource alertlogpdbPdb;
    
    static boolean isFirstCall = true;
    static String querySQL = System.getenv("QUERY_SQL");
    static String queryRetryIntervalString = System.getenv("QUERY_INTERVAL");
    static int DEFAULT_RETRY_INTERVAL = 30; // in seconds
    private boolean enabled = true;
    //currently logs are read from the beginning during startup.
    //When configuration is added in v2, config/functionality similar to promtail positions will be an option
//    private LocalDateTime alertLogQueryLastLocalDateTime;
    private java.sql.Timestamp alertLogQueryLastLocalDateTime;
    private int vashQueryLastSampleId = -1;
    private String alertLogDefaultQuery = "select ORIGINATING_TIMESTAMP, MODULE_ID, EXECUTION_CONTEXT_ID, MESSAGE_TEXT from TABLE(GV$(CURSOR(select * from v$diag_alert_ext)))";
    private String vashDefaultQuery = "select SAMPLE_ID, SAMPLE_TIME, SQL_ID, SQL_OPNAME, PROGRAM, MODULE, ACTION, CLIENT_ID, MACHINE, ECID " +
            "from TABLE(GV$(CURSOR(select * from v$active_session_history))) where ECID is not null and SAMPLE_ID > ";

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        // todo for each config entry write to different logger, eg...
        if (false) {
            final Logger LOGGER = Logger.getLogger(DBLogExporterResource.class.getName());
            //add perhaps devoted file option as well...
            FileHandler handler = new FileHandler("logexporterN-log.%u.%g.txt",
                    1024 * 1024, 10, true);
        }
        System.out.println("AlertLogExporterResource PDB:" + alertlogpdbPdb);
        System.out.println("AlertLogExporterResource alertLogDefaultQuery:" + alertLogDefaultQuery);
        System.out.println("AlertLogExporterResource vashDefaultQuery:" + vashDefaultQuery);
        try (Connection conn = alertlogpdbPdb.getConnection()) {
            while (enabled) {
                executeAlertLogQuery(conn);
                executeVASHQuery(conn);
                int queryRetryInterval = queryRetryIntervalString == null ||
                                queryRetryIntervalString.trim().equals("") ?
                                DEFAULT_RETRY_INTERVAL : Integer.parseInt(queryRetryIntervalString.trim());
                Thread.sleep(1000 * queryRetryInterval);
            }
        }
    }

    private void executeAlertLogQuery(Connection conn) throws SQLException {
        //todo  get from last NORMALIZED_TIMESTAMP inclusive
        /**
         * ORIGINATING_TIMESTAMP            TIMESTAMP(9) WITH TIME ZONE
         * NORMALIZED_TIMESTAMP             TIMESTAMP(9) WITH TIME ZONE
         */
        if(querySQL == null || querySQL.trim().equals("")) {
            querySQL = alertLogDefaultQuery;
        }
//        System.out.println("AlertLogExporterResource querySQL:" + querySQL + " alertLogQueryLastLocalDateTime:" + alertLogQueryLastLocalDateTime);
        PreparedStatement statement = conn.prepareStatement(isFirstCall ? querySQL : querySQL + " WHERE ORIGINATING_TIMESTAMP > ?");
        if (!isFirstCall) statement.setTimestamp(1, alertLogQueryLastLocalDateTime);
        ResultSet rs = statement.executeQuery();
        while (rs.next()) { //todo make dynamic for other SQL queries...
            java.sql.Timestamp localDateTime = rs.getObject("ORIGINATING_TIMESTAMP", java.sql.Timestamp.class);
            if (alertLogQueryLastLocalDateTime == null || localDateTime.after(alertLogQueryLastLocalDateTime)) {
                alertLogQueryLastLocalDateTime = localDateTime;
            }
            String keys[] = {"MODULE_ID", "EXECUTION_CONTEXT_ID", "MESSAGE_TEXT"};
            logKeyValue(rs, keys, localDateTime);
        }
        isFirstCall = false;
    }

    private void executeVASHQuery(Connection conn) throws SQLException {
        /**
         *      SAMPLE_ID                         NUMBER
         *      SAMPLE_TIME                       TIMESTAMP(3)
         *      SAMPLE_TIME_UTC                   TIMESTAMP(3)
         */
        // ECID will likely be null unless the scaling/stress lab (lab 4) has been run in order to generate enough load for a sample
        //   (or of course if any other activity that logs an ECID has been conducted on this pdb).
        //   todo this being the case this will not produce any logs unless the scaling lab is run and so
        //    we might want a where SQL_OPNAME=INSERT or  PROGRAM/MODULE like order-helidon as a default instead
        // todo use prepared statement and SAMPLE_TIME TIMESTAMP(3) instead of SAMPLE_ID NUMBER ...
        String vashQuery = vashDefaultQuery + vashQueryLastSampleId;
//        System.out.println("AlertLogExporterResource querySQL:" + vashQuery);
        PreparedStatement statement = conn.prepareStatement(vashQuery);
        ResultSet rs = statement.executeQuery();
        while (rs.next()) {
            int sampleId =  rs.getInt("SAMPLE_ID");
            if (sampleId > vashQueryLastSampleId) vashQueryLastSampleId = sampleId;
//            System.out.println("AlertLogExporterResource vashQueryLastSampleId:" + vashQueryLastSampleId);
            String keys[] = {"SAMPLE_ID", "SAMPLE_TIME", "SQL_ID", "SQL_OPNAME", "PROGRAM", "MODULE", "ACTION", "CLIENT_ID", "MACHINE", "ECID"};
            logKeyValue(rs, keys, null); //todo should be sample_time
        }
    }

    private void logKeyValue(ResultSet rs, String[] keys, Timestamp localDateTime) throws SQLException {
        String logString = "";
        for (int i=0; i<keys.length; i++)
            logString+= keys[i] + "=" + rs.getString(keys[i]) + " ";
        if (localDateTime != null) logString = "ORIGINATING_TIMESTAMP=" + localDateTime + " " + logString;
        System.out.println(logString);
    }

    @Path("/test")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterInventoryMessageReceived() {
        return Response.ok()
                .entity("test successful")
                .build();
    }
}