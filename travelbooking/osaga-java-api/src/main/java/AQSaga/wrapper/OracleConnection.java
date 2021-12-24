package AQSaga.wrapper;

import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.Arrays;

public class OracleConnection {

    oracle.jdbc.internal.OracleConnection connection;

    public OracleConnection(oracle.jdbc.internal.OracleConnection dbConnection) {
        connection = dbConnection;
    }

    /**
     * Begins a Saga by specifying the initiator of the saga and the saga timeout.
     *
     * @param initiatorName - Name of the participant that is initiating a saga. I
     *                      nitiator name is user supplied and should not be null.
     * @param timeout       - Maximum duration for which the saga can remain open withou
     *                      t being commited or rolledback. After the timeout duration the saga is marked ex
     *                      pired.
     * @param currentUser   - Current user schema. This is an internal parameter and
     *                      is used for some security and santiny checks.
     * @param version       - Saga version for the saga being initiated. For 23c this sh
     *                      ould always be 1.
     * @param opcode        - This is an internal parameter and specifies the operation c
     *                      ode for TTC main driver.
     * @param flags         - Additional Saga Flags if any.
     * @param spareNumeric  - Additional Numeric field(if required).
     * @param spareText     - Additional Text field(if required).
     * @return - sagaId generated which could be sent to other participants to enr
     * oll them in the same saga.
     * 2431    * @exception SQLException
     * @since 23
     */
    public byte[] beginSaga(
            String initiatorName,
            int timeout,
            String currentUser,
            int version,
            int opcode,
            int flags,
            int spareNumeric,
            String spareText) throws SQLException {

        System.out.println("OracleConnection.beginSaga initiatorName = " + initiatorName + ", timeout = " + timeout +
                ", currentUser = " + currentUser + ", version = " + version + ", opcode = " + opcode +
                ", flags = " + flags + ", spareNumeric = " + spareNumeric + ", spareText = " + spareText);
        CallableStatement cstmt = connection.prepareCall("{call BEGINSAGAWRAPPER(?,?)}");
        cstmt.setString("SAGANAME", initiatorName);
//        cstmt.setString("SAGANAME", "TravelAgency");
        cstmt.registerOutParameter("SAGAID", Types.VARCHAR);
        cstmt.execute();
        String sagaId = cstmt.getString("SAGAID");
        System.out.println("OracleConnection.beginSaga sagaId:" + sagaId);
        return sagaId.getBytes();
    }

    //this is not part of the interface, only temp convenience
    public void enrollParticipant(String sagaId, String schema, String sender, String recipient, String coordinator) throws SQLException {
        System.out.println("sagaId = " + sagaId + ", schema = " + schema + ", sender = " + sender + ", recipient = " + recipient + ", coordinator = " + coordinator);
         CallableStatement cstmt = connection.prepareCall("{call ENROLL_PARTICIPANT_IN_SAGA(?,?,?,?,?)}");
         cstmt.setString("PARTICIPANTTYPE", recipient);
         cstmt.setString("RESERVATIONTYPE", "car"); //todo take from payload
         cstmt.setString("RESERVATIONVALUE", "toyota"); //todo take from payload
         cstmt.setString("SAGANAME", sender);
         cstmt.setString("SAGAID", sagaId);
         cstmt.execute();
        System.out.println("OracleConnection.enrollParticipant end");
    }

    /**
     * Join a saga specified by the sagaId and the participant name and listen
     * to acknowledements sent by the coordinator.
     *
     * @param participantName - Name of the participant who recieved a sagaId from
     *                        an initiator. This should not be null.
     * @param sagaId          - The sagaId recieved from the initiator via the notification
     *                        callback. This should not be null.
     * @param coordinatorName - Name of the saga coordinator recieved via the noti
     *                        fication callback. This should not be null.
     * @param initiatorName   - Name of the saga initiator recieved via the notifica
     *                        tion callback. This should be not null.
     * @param timeout         - Maximum duration for which the saga can remain open withou
     *                        t being commited or rolledback. After the timeout duration the saga is marked ex
     *                        pired.
     * @param version         - Saga version for the saga being initiated. For 23c this sh
     *                        ould always be 1.
     * @param opcode          - This is an internal parameter and specifies the operation c
     *                        ode for TTC main driver.
     * @param flags           - Additional Saga Flags if any.
     * @param spareNumeric    - Additional Numeric field(if required).
     * @param spareText       - Additional Text field(if required).
     * @return - join status of this participant with the supplied sagaId.
     * @throws SQLException
     * @since 23
     */
    public Integer joinSaga(
            String participantName,
            byte[] sagaId,
            String coordinatorName,
            String initiatorName,
            int timeout,
            int version,
            int opcode,
            int flags,
            int spareNumeric,
            String spareText) throws SQLException {
//        dbms_saga.enroll_participant(saga_id, ‘TravelAgency’, ‘Flight’, ‘TACoordinator’, request);
        CallableStatement pstmt = connection.prepareCall("{call  join_saga_int(?,?)}");
        pstmt.setNString(1, "");
        pstmt.execute();
        return null;
    }

    /**
     * Commit or Rollback a saga either globally or locally by specifying the
     * participant/initiator and the saga id.
     *
     * @param participantName - Name of the participant/initiator who is performin
     *                        g the commit or rollback. This should never be null.
     * @param sagaId          - The sagaId being committed or rolledback. This should not b
     *                        e null.
     * @param currentUser     - Current user schema. This is an internal parameter and
     *                        is used for some security and santiny checks.
     * @param opcode          - This is an internal parameter and specifies the operation c
     *                        ode for TTC main driver.
     * @param flags           -  Additional Saga Flags if any.
     * @param spareNumeric    - Additional Numeric field(if required).
     * @param spareText       -  Additional Text field(if required).
     * @return - the commit/rollback status for the given participant with the sup
     * plied sagaId
     * @throws SQLException
     * @since 23
     */
    public Integer commitRollbackSaga(
            String participantName,
            byte[] sagaId,
            String currentUser,
            int opcode,
            int flags,
            int spareNumeric,
            String spareText) throws SQLException {
        System.out.println("participantName = " + participantName + ", sagaId = " + Arrays.toString(sagaId) +
                ", currentUser = " + currentUser + ", opcode = " + opcode +
                ", flags = " + flags + ", spareNumeric = " + spareNumeric + ", spareText = " + spareText);
//   OSAGA_ABORT = 4;     dbms_saga.rollback_saga('TravelAgency', saga_id);
//   OSAGA_COMMIT = 2;     dbms_saga.commit_saga('TravelAgency', saga_id);
//        CallableStatement pstmt = connection.prepareCall("{call CREATEDATAAPPUSER(?,?)}");
        CallableStatement pstmt = connection.prepareCall("{dbms_saga.rollback_saga(?, ?)}");
//        CallableStatement pstmt = connection.prepareCall("{dbms_saga.commit_saga('TravelAgency', saga_id)}");
        pstmt.setNString(1, "TravelAgency");
        pstmt.setNString(1, "");
        pstmt.execute();
        return null;
    }
//    public static final int OSAGA_BEGIN = 0;
//    public static final int OSAGA_JOIN = 1;
//    public static final int OSAGA_COMMIT = 2;
//    public static final int OSAGA_COMMIT_NTFN = 3;
//    public static final int OSAGA_ABORT = 4;
//    public static final int OSAGA_ABORT_NTFN = 5;
//    public static final int OSAGA_ACK = 6;
//    public static final int OSAGA_REQUEST = 7;
//    public static final int OSAGA_RESPONSE = 8;
//    public static final int OSAGA_COMMIT_FAIL = 9;
//    public static final int OSAGA_ABORT_FAIL = 10;
//    public static final int OSAGA_COMMIT_SUCCESS = 11;
//    public static final int OSAGA_ABORT_SUCCESS = 12;


    String callCommitOnSaga(Connection connection, String travelagencyid, String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call COMMITSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "commitSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }

    String callRollbackOnSaga(Connection connection, String travelagencyid, String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call ROLLBACKSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "commitSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }

    public void setAutoCommit(boolean b) throws SQLException {
        connection.setAutoCommit(b);
    }

    public String getSchema() throws SQLException {
        return connection.getSchema();
    }

}
