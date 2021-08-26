/*

 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package alertlogexporter;

import java.io.*;
import java.sql.*;
import java.time.LocalDateTime;

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

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
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


    /**
     * desc V$diag_alert_ext...
     *
     * Name                       Null? Type
     * -------------------------- ----- ---------------------------
     * ORIGINATING_TIMESTAMP            TIMESTAMP(9) WITH TIME ZONE
     * NORMALIZED_TIMESTAMP             TIMESTAMP(9) WITH TIME ZONE
     * ORGANIZATION_ID                  VARCHAR2(67)
     * COMPONENT_ID                     VARCHAR2(67)
     * HOST_ID                          VARCHAR2(67)
     * HOST_ADDRESS                     VARCHAR2(49)
     * MESSAGE_TYPE                     NUMBER
     * MESSAGE_LEVEL                    NUMBER
     * MESSAGE_ID                       VARCHAR2(67)
     * MESSAGE_GROUP                    VARCHAR2(67)
     * CLIENT_ID                        VARCHAR2(67)
     * MODULE_ID                        VARCHAR2(67)
     * PROCESS_ID                       VARCHAR2(35)
     * THREAD_ID                        VARCHAR2(67)
     * USER_ID                          VARCHAR2(131)
     * INSTANCE_ID                      VARCHAR2(67)
     * DETAILED_LOCATION                VARCHAR2(163)
     * UPSTREAM_COMP_ID                 VARCHAR2(103)
     * DOWNSTREAM_COMP_ID               VARCHAR2(103)
     * EXECUTION_CONTEXT_ID             VARCHAR2(103)
     * EXECUTION_CONTEXT_SEQUENCE       NUMBER
     * ERROR_INSTANCE_ID                NUMBER
     * ERROR_INSTANCE_SEQUENCE          NUMBER
     * MESSAGE_TEXT                     VARCHAR2(2051)
     * MESSAGE_ARGUMENTS                VARCHAR2(515)
     * SUPPLEMENTAL_ATTRIBUTES          VARCHAR2(515)
     * SUPPLEMENTAL_DETAILS             VARCHAR2(515)
     * PARTITION                        NUMBER
     * RECORD_ID                        NUMBER
     * FILENAME                         VARCHAR2(515)
     * LOG_NAME                         VARCHAR2(67)
     * PROBLEM_KEY                      VARCHAR2(553)
     * VERSION                          NUMBER
     * CON_UID                          NUMBER
     * CONTAINER_ID                     NUMBER
     * CONTAINER_NAME                   VARCHAR2(67)
     * CON_ID                           NUMBER
     */


    @Path("/test")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterInventoryMessageReceived() {
        return Response.ok()
                .entity("test successful")
                .build();
    }
}