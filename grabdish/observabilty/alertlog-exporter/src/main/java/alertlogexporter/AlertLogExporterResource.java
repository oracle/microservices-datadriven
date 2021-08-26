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
    @Named("orderpdb")
    PoolDataSource atpOrderPdb;

    @Inject
    @Named("inventorypdb")
    PoolDataSource atpInventoryPdb;

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        System.out.println("AlertLogExporterResource atpOrderPdb:" + atpOrderPdb);
        System.out.println("AlertLogExporterResource inventorypdb:" + atpInventoryPdb);
        File fout = new File("alert.log");
        FileOutputStream fos = new FileOutputStream(fout);
        BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(fos));
        logFromDataSourceToFile(bw, atpOrderPdb, "atpOrderPdb");
        logFromDataSourceToFile(bw, atpInventoryPdb, "atpInventoryPdb");
    }

    private void logFromDataSourceToFile(BufferedWriter bw, PoolDataSource poolDataSource, String datasourceName) throws SQLException, IOException {
        try (Connection conn = poolDataSource.getConnection()) {
            System.out.println("AlertLogExporterResource " + datasourceName + " connection:" + conn);
            PreparedStatement statement =
                    conn.prepareStatement("select ORIGINATING_TIMESTAMP, MODULE_ID, EXECUTION_CONTEXT_ID, MESSAGE_TEXT from V$diag_alert_ext");
            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                LocalDateTime localDateTime = rs.getObject("ORIGINATING_TIMESTAMP", LocalDateTime.class);
                String moduleId = rs.getString("MODULE_ID");
                String ecid = rs.getString("EXECUTION_CONTEXT_ID");
                String messageText = rs.getString("MESSAGE_TEXT");
                String recordToWriteToFile = localDateTime + " " + moduleId + " " + "ecid=" + ecid + " " + messageText;
                System.out.println("AlertLogExporterResource about to write recordToWriteToFile:" + recordToWriteToFile);
                bw.write(recordToWriteToFile);
                bw.newLine();
            }
            bw.close();
        }
    }


    /**
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