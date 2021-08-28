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

     descr V$SESSION...
    Name                          Null? Type
----------------------------- ----- --------------
    SADDR                               RAW(8 BYTE)
    SID                                 NUMBER
    SERIAL#                             NUMBER
    AUDSID                              NUMBER
    PADDR                               RAW(8 BYTE)
    USER#                               NUMBER
    USERNAME                            VARCHAR2(128)
    COMMAND                             NUMBER
    OWNERID                             NUMBER
    TADDR                               VARCHAR2(16)
    LOCKWAIT                            VARCHAR2(16)
    STATUS                              VARCHAR2(8)
    SERVER                              VARCHAR2(9)
    SCHEMA#                             NUMBER
    SCHEMANAME                          VARCHAR2(128)
    OSUSER                              VARCHAR2(128)
    PROCESS                             VARCHAR2(24)
    MACHINE                             VARCHAR2(64)
    PORT                                NUMBER
    TERMINAL                            VARCHAR2(30)
    PROGRAM                             VARCHAR2(48)
    TYPE                                VARCHAR2(10)
    SQL_ADDRESS                         RAW(8 BYTE)
    SQL_HASH_VALUE                      NUMBER
    SQL_ID                              VARCHAR2(13)
    SQL_CHILD_NUMBER                    NUMBER
    SQL_EXEC_START                      DATE
    SQL_EXEC_ID                         NUMBER
    PREV_SQL_ADDR                       RAW(8 BYTE)
    PREV_HASH_VALUE                     NUMBER
    PREV_SQL_ID                         VARCHAR2(13)
    PREV_CHILD_NUMBER                   NUMBER
    PREV_EXEC_START                     DATE
    PREV_EXEC_ID                        NUMBER
    PLSQL_ENTRY_OBJECT_ID               NUMBER
    PLSQL_ENTRY_SUBPROGRAM_ID           NUMBER
    PLSQL_OBJECT_ID                     NUMBER
    PLSQL_SUBPROGRAM_ID                 NUMBER
    MODULE                              VARCHAR2(64)
    MODULE_HASH                         NUMBER
    ACTION                              VARCHAR2(64)
    ACTION_HASH                         NUMBER
    CLIENT_INFO                         VARCHAR2(64)
    FIXED_TABLE_SEQUENCE                NUMBER
    ROW_WAIT_OBJ#                       NUMBER
    ROW_WAIT_FILE#                      NUMBER
    ROW_WAIT_BLOCK#                     NUMBER
    ROW_WAIT_ROW#                       NUMBER
    TOP_LEVEL_CALL#                     NUMBER
    LOGON_TIME                          DATE
    LAST_CALL_ET                        NUMBER
    PDML_ENABLED                        VARCHAR2(3)
    FAILOVER_TYPE                       VARCHAR2(13)
    FAILOVER_METHOD                     VARCHAR2(10)
    FAILED_OVER                         VARCHAR2(3)
    RESOURCE_CONSUMER_GROUP             VARCHAR2(32)
    PDML_STATUS                         VARCHAR2(8)
    PDDL_STATUS                         VARCHAR2(8)
    PQ_STATUS                           VARCHAR2(8)
    CURRENT_QUEUE_DURATION              NUMBER
    CLIENT_IDENTIFIER                   VARCHAR2(64)
    BLOCKING_SESSION_STATUS             VARCHAR2(11)
    BLOCKING_INSTANCE                   NUMBER
    BLOCKING_SESSION                    NUMBER
    FINAL_BLOCKING_SESSION_STATUS       VARCHAR2(11)
    FINAL_BLOCKING_INSTANCE             NUMBER
    FINAL_BLOCKING_SESSION              NUMBER
    SEQ#                                NUMBER
    EVENT#                              NUMBER
    EVENT                               VARCHAR2(64)
    P1TEXT                              VARCHAR2(64)
    P1                                  NUMBER
    P1RAW                               RAW(8 BYTE)
    P2TEXT                              VARCHAR2(64)
    P2                                  NUMBER
    P2RAW                               RAW(8 BYTE)
    P3TEXT                              VARCHAR2(64)
    P3                                  NUMBER
    P3RAW                               RAW(8 BYTE)
    WAIT_CLASS_ID                       NUMBER
    WAIT_CLASS#                         NUMBER
    WAIT_CLASS                          VARCHAR2(64)
    WAIT_TIME                           NUMBER
    SECONDS_IN_WAIT                     NUMBER
    STATE                               VARCHAR2(19)
    WAIT_TIME_MICRO                     NUMBER
    TIME_REMAINING_MICRO                NUMBER
    TOTAL_TIME_WAITED_MICRO             NUMBER
    HEUR_TIME_WAITED_MICRO              NUMBER
    TIME_SINCE_LAST_WAIT_MICRO          NUMBER
    SERVICE_NAME                        VARCHAR2(64)
    SQL_TRACE                           VARCHAR2(8)
    SQL_TRACE_WAITS                     VARCHAR2(5)
    SQL_TRACE_BINDS                     VARCHAR2(5)
    SQL_TRACE_PLAN_STATS                VARCHAR2(10)
    SESSION_EDITION_ID                  NUMBER
    CREATOR_ADDR                        RAW(8 BYTE)
    CREATOR_SERIAL#                     NUMBER
    ECID                                VARCHAR2(64)
    SQL_TRANSLATION_PROFILE_ID          NUMBER
    PGA_TUNABLE_MEM                     NUMBER
    SHARD_DDL_STATUS                    VARCHAR2(8)
    CON_ID                              NUMBER
    EXTERNAL_NAME                       VARCHAR2(1024)
    PLSQL_DEBUGGER_CONNECTED            VARCHAR2(5)

     desc V$ACTIVE_SESSION_HISTORY...
     Name                        Null? Type
     --------------------------- ----- ------------
     SAMPLE_ID                         NUMBER
     SAMPLE_TIME                       TIMESTAMP(3)
     SAMPLE_TIME_UTC                   TIMESTAMP(3)
     USECS_PER_ROW                     NUMBER
     IS_AWR_SAMPLE                     VARCHAR2(1)
     SESSION_ID                        NUMBER
     SESSION_SERIAL#                   NUMBER
     SESSION_TYPE                      VARCHAR2(10)
     FLAGS                             NUMBER
     USER_ID                           NUMBER
     SQL_ID                            VARCHAR2(13)
     IS_SQLID_CURRENT                  VARCHAR2(1)
     SQL_CHILD_NUMBER                  NUMBER
     SQL_OPCODE                        NUMBER
     SQL_OPNAME                        VARCHAR2(64)
     FORCE_MATCHING_SIGNATURE          NUMBER
     TOP_LEVEL_SQL_ID                  VARCHAR2(13)
     TOP_LEVEL_SQL_OPCODE              NUMBER
     SQL_ADAPTIVE_PLAN_RESOLVED        NUMBER
     SQL_FULL_PLAN_HASH_VALUE          NUMBER
     SQL_PLAN_HASH_VALUE               NUMBER
     SQL_PLAN_LINE_ID                  NUMBER
     SQL_PLAN_OPERATION                VARCHAR2(30)
     SQL_PLAN_OPTIONS                  VARCHAR2(30)
     SQL_EXEC_ID                       NUMBER
     SQL_EXEC_START                    DATE
     PLSQL_ENTRY_OBJECT_ID             NUMBER
     PLSQL_ENTRY_SUBPROGRAM_ID         NUMBER
     PLSQL_OBJECT_ID                   NUMBER
     PLSQL_SUBPROGRAM_ID               NUMBER
     QC_INSTANCE_ID                    NUMBER
     QC_SESSION_ID                     NUMBER
     QC_SESSION_SERIAL#                NUMBER
     PX_FLAGS                          NUMBER
     EVENT                             VARCHAR2(64)
     EVENT_ID                          NUMBER
     EVENT#                            NUMBER
     SEQ#                              NUMBER
     P1TEXT                            VARCHAR2(64)
     P1                                NUMBER
     P2TEXT                            VARCHAR2(64)
     P2                                NUMBER
     P3TEXT                            VARCHAR2(64)
     P3                                NUMBER
     WAIT_CLASS                        VARCHAR2(64)
     WAIT_CLASS_ID                     NUMBER
     WAIT_TIME                         NUMBER
     SESSION_STATE                     VARCHAR2(7)
     TIME_WAITED                       NUMBER
     BLOCKING_SESSION_STATUS           VARCHAR2(11)
     BLOCKING_SESSION                  NUMBER
     BLOCKING_SESSION_SERIAL#          NUMBER
     BLOCKING_INST_ID                  NUMBER
     BLOCKING_HANGCHAIN_INFO           VARCHAR2(1)
     CURRENT_OBJ#                      NUMBER
     CURRENT_FILE#                     NUMBER
     CURRENT_BLOCK#                    NUMBER
     CURRENT_ROW#                      NUMBER
     TOP_LEVEL_CALL#                   NUMBER
     TOP_LEVEL_CALL_NAME               VARCHAR2(64)
     CONSUMER_GROUP_ID                 NUMBER
     XID                               RAW(8 BYTE)
     REMOTE_INSTANCE#                  NUMBER
     TIME_MODEL                        NUMBER
     IN_CONNECTION_MGMT                VARCHAR2(1)
     IN_PARSE                          VARCHAR2(1)
     IN_HARD_PARSE                     VARCHAR2(1)
     IN_SQL_EXECUTION                  VARCHAR2(1)
     IN_PLSQL_EXECUTION                VARCHAR2(1)
     IN_PLSQL_RPC                      VARCHAR2(1)
     IN_PLSQL_COMPILATION              VARCHAR2(1)
     IN_JAVA_EXECUTION                 VARCHAR2(1)
     IN_BIND                           VARCHAR2(1)
     IN_CURSOR_CLOSE                   VARCHAR2(1)
     IN_SEQUENCE_LOAD                  VARCHAR2(1)
     IN_INMEMORY_QUERY                 VARCHAR2(1)
     IN_INMEMORY_POPULATE              VARCHAR2(1)
     IN_INMEMORY_PREPOPULATE           VARCHAR2(1)
     IN_INMEMORY_REPOPULATE            VARCHAR2(1)
     IN_INMEMORY_TREPOPULATE           VARCHAR2(1)
     IN_TABLESPACE_ENCRYPTION          VARCHAR2(1)
     CAPTURE_OVERHEAD                  VARCHAR2(1)
     REPLAY_OVERHEAD                   VARCHAR2(1)
     IS_CAPTURED                       VARCHAR2(1)
     IS_REPLAYED                       VARCHAR2(1)
     IS_REPLAY_SYNC_TOKEN_HOLDER       VARCHAR2(1)
     SERVICE_HASH                      NUMBER
     PROGRAM                           VARCHAR2(48)
     MODULE                            VARCHAR2(64)
     ACTION                            VARCHAR2(64)
     CLIENT_ID                         VARCHAR2(64)
     MACHINE                           VARCHAR2(64)
     PORT                              NUMBER
     ECID                              VARCHAR2(64)
     DBREPLAY_FILE_ID                  NUMBER
     DBREPLAY_CALL_COUNTER             NUMBER
     TM_DELTA_TIME                     NUMBER
     TM_DELTA_CPU_TIME                 NUMBER
     TM_DELTA_DB_TIME                  NUMBER
     DELTA_TIME                        NUMBER
     DELTA_READ_IO_REQUESTS            NUMBER
     DELTA_WRITE_IO_REQUESTS           NUMBER
     DELTA_READ_IO_BYTES               NUMBER
     DELTA_WRITE_IO_BYTES              NUMBER
     DELTA_INTERCONNECT_IO_BYTES       NUMBER
     DELTA_READ_MEM_BYTES              NUMBER
     PGA_ALLOCATED                     NUMBER
     TEMP_SPACE_ALLOCATED              NUMBER
     CON_DBID                          NUMBER
     CON_ID                            NUMBER
     DBOP_NAME                         VARCHAR2(30)
     DBOP_EXEC_ID                      NUMBER

     desc V$DIAG_TRACE_FILE_CONTENTS...
     ADR_HOME             VARCHAR2(444)
     TRACE_FILENAME       VARCHAR2(68)
     RECORD_LEVEL         NUMBER
     PARENT_LEVEL         NUMBER
     RECORD_TYPE          NUMBER
     TIMESTAMP            TIMESTAMP(3) WITH TIME ZONE
     PAYLOAD              VARCHAR2(4000)
     SECTION_ID           NUMBER
     SECTION_NAME         VARCHAR2(64)
     COMPONENT_NAME       VARCHAR2(64)
     OPERATION_NAME       VARCHAR2(64)
     FILE_NAME            VARCHAR2(64)
     FUNCTION_NAME        VARCHAR2(64)
     LINE_NUMBER          NUMBER
     THREAD_ID            VARCHAR2(64)
     SESSION_ID           NUMBER
     SERIAL#              NUMBER
     CON_UID              NUMBER
     CONTAINER_NAME       VARCHAR2(64)
     CON_ID               NUMBER


     select di.value path, 'alert_' || i.instance_name || '.log' from v$diag_info di, v$instance i where di.name = 'Diag Trace'


     view SQL logs from  V$SQL, V$SQLAREA views
--
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