package io.helidon.data.examples;

import oracle.jdbc.internal.OraclePreparedStatement;

import java.sql.*;
import java.util.HashMap;
import java.util.Map;

public class ImplementionWithoutOSaga implements Runnable {

    private boolean isServerRunning = true;
    private int timeoutProcessingInteval = 60; //seconds
    private int timeoutExpirationValue = 60 * 60; //one hour
    private Map<String, String> sagaToStartTimeExpirationMap = new HashMap();
    //Saga states..
    private static final String ACTIVE = "ACTIVE";
    private static final String COMPLETING = "COMPLETING";
    private static final String ABORTING = "ABORTING";


    public String beginSaga(Connection connection, String travelagencyid) {
        long currentTime = System.currentTimeMillis();
        String sagaId = "" + currentTime;
        PreparedStatement cstmt = null;
        try {
            cstmt = connection.prepareCall("insert into sagastate(?,?,?)");
            cstmt.setString(1, sagaId);
            cstmt.setString(2, "ACTIVE");
            cstmt.setLong(3, currentTime);
            cstmt.execute();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
            return null;
        }
        return sagaId;
    }

    public void logSaga(Connection connection, String travelagencyid, String sagaId) {
        PreparedStatement cstmt = null;
        try {
            cstmt = connection.prepareCall("insert into travelagency_participants_sagastate(?,?,?)");
            cstmt.setString(1, sagaId);
            cstmt.setString(2, "FLIGHT");
            cstmt.setString(3, "ACTIVE");
            cstmt.execute();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }
    
    public void logAndAddFlightParticipantToSaga(Connection connection, String travelagencyid, String sagaId) {
        PreparedStatement cstmt = null;
        try {
            cstmt = connection.prepareCall("insert into travelagency_participants_sagastate(?,?,?)");
            cstmt.setString(1, sagaId);
            cstmt.setString(2, "FLIGHT");
            cstmt.setString(3, "ACTIVE");
            cstmt.execute();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }

    public void saveFlightInventoryBeforeStateInDevotedInventoryJournalTable(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement)
                connection.prepareStatement(
                        "insert into flightparticipant_sagajournal set seats = seats - 1 where sagaId = ? returning seats into ?")) {
            st.setInt(1, 1);
            st.registerReturnParameter(2, Types.INTEGER);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String seats = res.getString(1);
                System.out.println("saveFlightInventoryStateInDevotedInventoryJournalTable seats:" + seats);
            }
        }
    }

    public void reserveFlight(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement)
                connection.prepareStatement("update flights set seats = seats - 1 where id = ? returning seats into ?")) {
            st.setInt(1, 1);
            st.registerReturnParameter(2, Types.INTEGER);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String seats = res.getString(1);
                System.out.println("adjustFlightInventory seats:" + seats);
            }
        }
    }

    public void addHotelParticipantToSaga(Connection connection, String travelagencyid, String sagaId) {
        PreparedStatement cstmt = null;
        try {
            cstmt = connection.prepareCall("insert into travelagency_participants_sagastate(?,?,?)");
            cstmt.setString(1, sagaId);
            cstmt.setString(2, "HOTEL");
            cstmt.setString(3, "ACTIVE");
            cstmt.execute();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }

    public void saveHotelInventoryBeforeStateInDevotedInventoryJournalTable(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement)
                connection.prepareStatement(
                        "insert into hotelparticipant_sagajournal set seats = seats - 1 where sagaId = ? returning seats into ?")) {
            st.setInt(1, 1);
            st.registerReturnParameter(2, Types.INTEGER);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String seats = res.getString(1);
                System.out.println("saveFlightInventoryStateInDevotedInventoryJournalTable seats:" + seats);
            }
        }
    }

    public void adjustHotelInventory(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement)
                connection.prepareStatement("update hotel set seats = seats - 1 where id = ? returning seats into ?")) {
            st.setInt(1, 1);
            st.registerReturnParameter(2, Types.INTEGER);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String seats = res.getString(1);
                System.out.println("adjustFlightInventory seats:" + seats);
            }
        }
    }


    public void setStateToCommittingOnSaga(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        PreparedStatement cstmt = connection.prepareCall("update sagastate set state = ? where sagaId = ?");
        cstmt.setString(2, sagaId);
        cstmt.setString(1, "COMMITTING");
        cstmt.execute();
    }

    public void callCommitOnAllParticipants(Connection connection, String travelagencyid, String sagaId) {
        // call commit/cleanup on participants
        // participants purge journal tables
    }

    public void setStateToCommittedOnParticipants(Connection connection, String travelagencyid, String sagaId) {
    }



    public void setStateToRollingbackOnSaga(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        PreparedStatement cstmt = connection.prepareCall("update sagastate set state = ? where sagaId = ?");
        cstmt.setString(2, sagaId);
        cstmt.setString(1, "ROLLINGBACK");
        cstmt.execute();
    }

    public void callRollbackOnAllParticipants(Connection connection, String travelagencyid, String sagaId) {
    }


    public void setStateToRolledbackOnParticipants(Connection connection, String travelagencyid, String sagaId) {
    }

    public void purgeSagaAndParticipantEntries(Connection connection, String travelagencyid, String sagaId) throws SQLException {
        PreparedStatement cstmt = connection.prepareCall("delete sagastate where sagaId = ?");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        cstmt = connection.prepareCall("delete travelagency_participants_sagastate where sagaId = ?");
        cstmt.setString(1, sagaId);
        cstmt.execute();
    }

    // Server startup recovery and expiration/timeout processing
    public void processRecoveryForSagaStateInDevotedSagaTable(Connection connection) {
        try {
            //additional tables needed to bookkeep sagas
            connection.createStatement().execute("create table sagastate(sagaid varchar(64), state varchar(64), begintime integer)");
            connection.createStatement().execute("create table sagaparticipantstate(sagaid varchar(64), participant varchar(64), state varchar(64))");
//            connection.createStatement().execute("create table flightparticipant_sagajournal(sagaid varchar(64), participantcount integer)");
//            connection.createStatement().execute("create table hotelparticipant_sagajournal(sagaid varchar(64), participantcount integer)");
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }

    public void startSagaExpirationProcessing() {
        new Thread(this).start();
    }

    @Override
    public void run() {
        while (isServerRunning) {
            for (Object sagaId : sagaToStartTimeExpirationMap.keySet()) {
                if ((System.currentTimeMillis() - Long.parseLong(sagaToStartTimeExpirationMap.get(sagaId))) > (this.timeoutExpirationValue * 1000)) {
                    //do not allow further enlistment and
                    //abort...
                }
            }
            try {
                Thread.sleep(timeoutProcessingInteval * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

}
