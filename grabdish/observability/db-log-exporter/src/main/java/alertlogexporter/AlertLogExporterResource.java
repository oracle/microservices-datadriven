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

    /**
     Example queries...
     select * from TABLE(GV$(CURSOR(select * from V$SESSION)))
     select * from TABLE(GV$(CURSOR(select * from V$ACTIVE_SESSION_HISTORY)))
     SELECT SQL_ID, SQL_FULLTEXT FROM v$sqlarea
     SELECT SQL_ID, SQL_FULLTEXT FROM TABLE(GV$(CURSOR(select * from v$sqlarea)))  where SQL_ID='2ygnt73ck3jk8'
     SELECT  FROM V$SQL

     SELECT distinct sql_id FROM gv$active_session_history ash WHERE ash.sample_time > SYSDATE - 1/24 and USER_ID = 151


     select di.value path, 'alert_' || i.instance_name || '.log' from v$diag_info di, v$instance i where di.name = 'Diag Trace'

     https://www.dba-scripts.com/scripts/diagnostic-and-tuning/oracle-active-session-history-ash/top-10-queries-active_session_history/
     https://techgoeasy.com/ash-decoded/
     */
/**

 // Most active session in last 6hrs
 SELECT sql_id,COUNT(*),ROUND(COUNT(*)/SUM(COUNT(*)) OVER(), 2) PCTLOAD
 FROM gv$active_session_history
 WHERE sample_time > SYSDATE - 1/24
 AND session_type = 'BACKGROUND'
 GROUP BY sql_id
 ORDER BY COUNT(*) DESC;
 SELECT sql_id,COUNT(*),ROUND(COUNT(*)/SUM(COUNT(*)) OVER(), 2) PCTLOAD
 FROM gv$active_session_history
 WHERE sample_time > SYSDATE - 1/24
 AND session_type = 'FOREGROUND'
 GROUP BY sql_id
 ORDER BY COUNT(*) DESC;

 // Most I/O intensive sql in last 6hrs

 SELECT sql_id, user_id COUNT(*)
 FROM gv$active_session_history ash, gv$event_name evt
 WHERE ash.sample_time > SYSDATE - 1/24
 AND ash.session_state = 'WAITING'
 AND ash.event_id = evt.event_id
 AND evt.wait_class = 'User I/O'
 GROUP BY sql_id, user_id
 ORDER BY COUNT(*) DESC;

    SELECT user_id, sql_id
    FROM gv$active_session_history ash, gv$event_name evt
    WHERE ash.sample_time > SYSDATE - 6/24
    AND ash.session_state = 'WAITING'
    AND ash.event_id = evt.event_id
    AND evt.wait_class = 'User I/O'

    select USER_ID,USERNAME from DBA_USERS where USER_ID = 151

*//
    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        // todo for each config entry write to different logger and file...
        if (false) {
            final Logger LOGGER = Logger.getLogger(AlertLogExporterResource.class.getName());
            FileHandler handler = new FileHandler("logexporterN-log.%u.%g.txt",
                    1024 * 1024, 10, true);
        }
        System.out.println("AlertLogExporterResource alertlogpdbPdb:" + alertlogpdbPdb);
        try (Connection conn = alertlogpdbPdb.getConnection()) {
            if(querySQL == null || querySQL.trim().equals("")) {
                querySQL = "select ORIGINATING_TIMESTAMP, MODULE_ID, EXECUTION_CONTEXT_ID, MESSAGE_TEXT from V$diag_alert_ext";
                System.out.println("AlertLogExporterResource no QUERY_SQL set in environment, using default");
            }
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