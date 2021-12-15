package io.helidon.data.examples;

import java.sql.*;

public class OSagaComparison {
    ImplementionWithoutOSaga implementionWithoutOSaga = new ImplementionWithoutOSaga();
    ImplementionWithOSaga implementionWithOSaga = new ImplementionWithOSaga();

    //__________________________ WITHOUT OSAGA __________________________

    boolean isServerInitiatialized = false;

    void startUpLogicWithoutOSaga(Connection connection) {
        if(isServerInitiatialized) return;
        implementionWithoutOSaga.processRecoveryForSagaStateInDevotedSagaTable(connection);
        implementionWithoutOSaga.startSagaExpirationProcessing();
        isServerInitiatialized = true;
    }

    String withoutOSaga(Connection connection, String travelagencyid, boolean isCommit) throws SQLException {
        startUpLogicWithoutOSaga(connection);
        String sagaId = implementionWithoutOSaga.beginSaga(connection, travelagencyid);
        implementionWithoutOSaga.logSaga(connection, travelagencyid, sagaId);
        implementionWithoutOSaga.logAndAddFlightParticipantToSaga(connection, travelagencyid, sagaId);
        implementionWithoutOSaga.reserveFlight(connection, travelagencyid, sagaId); //sends message to flight service
//        implementionWithoutOSaga.logAndAddHotelParticipantToSaga(connection, travelagencyid, sagaId);
//        implementionWithoutOSaga.reserveHotel(connection, travelagencyid, sagaId); //sends message to hotel service
        if (isCommit)  {
            connection.setAutoCommit(false); //if not using AQ additional steps are required to insure idempotence
            implementionWithoutOSaga.callCommitOnAllParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.setStateToCommittedOnParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, travelagencyid, sagaId);
            connection.commit();
            return sagaId;
        }  else  {
            connection.setAutoCommit(false); //if not using AQ additional steps are required to insure idempotence
            implementionWithoutOSaga.callRollbackOnAllParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.setStateToRolledbackOnParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, travelagencyid, sagaId);
            connection.commit();
            return sagaId;
        }
    }

    //__________________________ WITH OSAGA __________________________

    String withOSaga(Connection connection, String travelagencyid, boolean isCommit)  throws SQLException {
        String sagaId = implementionWithOSaga.beginOSaga(connection, travelagencyid);
        implementionWithOSaga.reserveFlight(connection, travelagencyid, sagaId); //sends message to flight service
//        implementionWithOSaga.reserveHotel(connection, travelagencyid, sagaId); //sends message to hotel service
        if (isCommit)  return implementionWithOSaga.callCommitOnSaga(connection, travelagencyid, sagaId);
        else  return implementionWithOSaga.callRollbackOnSaga(connection, travelagencyid, sagaId);
    }



}
