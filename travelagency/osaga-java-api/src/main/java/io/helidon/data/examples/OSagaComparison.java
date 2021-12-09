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

    String withoutOSaga(Connection connection, String orderid, boolean isCommit) throws SQLException {
        startUpLogicWithoutOSaga(connection);
        String sagaId = implementionWithoutOSaga.beginSaga(connection, orderid);
        implementionWithoutOSaga.logSaga(connection, orderid, sagaId);
        implementionWithoutOSaga.logAndAddFlightParticipantToSaga(connection, orderid, sagaId);
        implementionWithoutOSaga.reserveFlight(connection, orderid, sagaId); //sends message to flight service
//        implementionWithoutOSaga.logAndAddHotelParticipantToSaga(connection, orderid, sagaId);
//        implementionWithoutOSaga.reserveHotel(connection, orderid, sagaId); //sends message to hotel service
        if (isCommit)  {
            connection.setAutoCommit(false); //if not using AQ additional steps are required to insure idempotence
            implementionWithoutOSaga.callCommitOnAllParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.setStateToCommittedOnParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, orderid, sagaId);
            connection.commit();
            return sagaId;
        }  else  {
            connection.setAutoCommit(false); //if not using AQ additional steps are required to insure idempotence
            implementionWithoutOSaga.callRollbackOnAllParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.setStateToRolledbackOnParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, orderid, sagaId);
            connection.commit();
            return sagaId;
        }
    }

    //__________________________ WITH OSAGA __________________________

    String withOSaga(Connection connection, String orderid, boolean isCommit)  throws SQLException {
        String sagaId = implementionWithOSaga.beginOSaga(connection, orderid);
        implementionWithOSaga.reserveFlight(connection, orderid, sagaId); //sends message to flight service
//        implementionWithOSaga.reserveHotel(connection, orderid, sagaId); //sends message to hotel service
        if (isCommit)  return implementionWithOSaga.callCommitOnSaga(connection, orderid, sagaId);
        else  return implementionWithOSaga.callRollbackOnSaga(connection, orderid, sagaId);
    }



}
