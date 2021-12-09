package io.helidon.data.examples;

import java.sql.*;

public class ImplementionWithOSaga {

    String beginOSaga(Connection connection, String orderid)  throws SQLException {
        CallableStatement cstmt = connection.prepareCall("{call BEGINTRAVELAGENCYSAGA(?,?)}");
        cstmt.setString("SAGANAME", "TravelAgency");
        cstmt.registerOutParameter("SAGAID", Types.VARCHAR);
        cstmt.execute();
        String sagaId = cstmt.getString("SAGAID");
        return sagaId;
    }

    void reserveFlight(Connection connection, String orderid, String sagaId)  throws SQLException {
        CallableStatement cstmt = connection.prepareCall("{call REGISTER_PARTICIPANT_IN_SAGA(?,?,?,?,?)}");
        cstmt.setString("PARTICIPANTTYPE", "Airline");
        cstmt.setString("RESERVATIONTYPE", "flight");
        cstmt.setString("RESERVATIONVALUE", "United");
        cstmt.setString("SAGANAME", "TravelAgency");
        cstmt.setString("SAGAID", sagaId);
        cstmt.execute();
    }


    public void reserveHotel(Connection connection, String orderid, String sagaId) throws SQLException {
        CallableStatement cstmt = connection.prepareCall("{call ADDHOTELTO_TRAVELAGENCYSAGA(?,?)}");
        cstmt.setString("SAGANAME", "TravelAgency");
        cstmt.setString("SAGID", sagaId);
        cstmt.execute();
    }

    String callCommitOnSaga(Connection connection, String orderid, String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call COMMITSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "commitSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }

    String callRollbackOnSaga(Connection connection, String orderid, String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call ROLLBACKSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "commitSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }
}
