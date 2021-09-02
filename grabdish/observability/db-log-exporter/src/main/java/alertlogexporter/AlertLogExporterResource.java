/*

 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package alertlogexporter;

import java.io.*;
import java.sql.*;
import java.time.LocalDateTime;
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
public class AlertLogExporterResource {

    @Inject
    @Named("alertlogpdb")
    PoolDataSource alertlogpdbPdb;
    
    static String querySQL = System.getenv("QUERY_SQL");
    private boolean enabled = true;

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        // todo for each config entry write to different logger and file...
        if (false) {
            final Logger LOGGER = Logger.getLogger(AlertLogExporterResource.class.getName());
            FileHandler handler = new FileHandler("logexporterN-log.%u.%g.txt",
                    1024 * 1024, 10, true);
        }
        System.out.println("AlertLogExporterResource PDB:" + alertlogpdbPdb);
        try (Connection conn = alertlogpdbPdb.getConnection()) {
            if(querySQL == null || querySQL.trim().equals("")) {
                querySQL = "select ORIGINATING_TIMESTAMP, MODULE_ID, EXECUTION_CONTEXT_ID, MESSAGE_TEXT from TABLE(GV$(CURSOR(select * from v$diag_alert_ext)))";
                System.out.println("AlertLogExporterResource no QUERY_SQL set in environment, using default");
            }
            executeAlertLogQuery(conn);
            while (enabled) {
                executeVASHQuery(conn);
                Thread.sleep(1000 * 30);
            }
        }
    }

    private void executeAlertLogQuery(Connection conn) throws SQLException {
        System.out.println("AlertLogExporterResource querySQL:" + querySQL);
        PreparedStatement statement = conn.prepareStatement(querySQL);
        ResultSet rs = statement.executeQuery();
        while (rs.next()) { //todo make dynamic for other SQL queries...
            LocalDateTime localDateTime = rs.getObject("ORIGINATING_TIMESTAMP", LocalDateTime.class);
            String moduleId = rs.getString("MODULE_ID");
            String ecid = rs.getString("EXECUTION_CONTEXT_ID");
            String messageText = rs.getString("MESSAGE_TEXT");
            String recordToWrite = localDateTime + " moduleId=" + moduleId + " " + "ecid=" + ecid + " " + messageText;
            System.out.println(recordToWrite);
        }
    }

    private void executeVASHQuery(Connection conn) throws SQLException {
        String vashQuery = "select SAMPLE_ID, SAMPLE_TIME, SQL_ID, SQL_OPNAME, PROGRAM, MODULE, ACTION, CLIENT_ID, MACHINE, ECID from TABLE(GV$(CURSOR(select * from v$active_session_history))) where ecid is not null";
        System.out.println("AlertLogExporterResource querySQL:" + vashQuery);
        PreparedStatement statement = conn.prepareStatement(vashQuery);
        ResultSet rs = statement.executeQuery();
        while (rs.next()) {
            String keys[] = {"SAMPLE_ID", "SAMPLE_TIME", "SQL_ID", "SQL_OPNAME", "PROGRAM", "MODULE", "ACTION", "CLIENT_ID", "MACHINE", "ECID"};
            logKeyValue(rs, keys);
        }
    }

    private void logKeyValue(ResultSet rs, String keys[]) throws SQLException {
        String logString = null;
        for (int i=0; i<keys.length; i++)
            logString+= keys[i] + "=" + rs.getString(keys[i]);
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