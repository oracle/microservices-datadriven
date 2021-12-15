package io.helidon.data.examples;

import java.sql.Connection;
import java.sql.SQLException;


public class OSagaWithAutoCompensateComparison {
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
        implementionWithoutOSaga.logAndAddFlightParticipantToSaga(connection, travelagencyid, sagaId);
        connection.setAutoCommit(false);
        implementionWithoutOSaga.saveFlightInventoryBeforeStateInDevotedInventoryJournalTable(connection, travelagencyid, sagaId);
        implementionWithoutOSaga.reserveFlight(connection, travelagencyid, sagaId);
        connection.commit();
//        implementionWithoutOSaga.addHotelParticipantToSaga(connection, travelagencyid, sagaId);
//        connection.setAutoCommit(false);
//        implementionWithoutOSaga.saveHotelInventoryBeforeStateInDevotedInventoryJournalTable(connection, travelagencyid, sagaId);
//        implementionWithoutOSaga.adjustHotelInventory(connection, travelagencyid, sagaId);
//        connection.commit();
        if (isCommit)  {
            implementionWithoutOSaga.setStateToCommittingOnSaga(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.callCommitOnAllParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.setStateToCommittedOnParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, travelagencyid, sagaId);
            return sagaId;
        }  else  {
            implementionWithoutOSaga.setStateToRollingbackOnSaga(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.callRollbackOnAllParticipants(connection, travelagencyid, sagaId);
            // participants set value back to original based on log
            // participants purge journal tables
            // set state to committed on each participant upon return
            implementionWithoutOSaga.setStateToRolledbackOnParticipants(connection, travelagencyid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, travelagencyid, sagaId);
            return sagaId;
        }
    }

    //__________________________ WITH OSAGA __________________________

    String withOSaga(Connection connection, String travelagencyid, boolean isCommit)  throws SQLException {
        String sagaId = implementionWithOSaga.beginOSaga(connection, travelagencyid);
//        implementionWithOSaga.reserveHotel(connection, travelagencyid, sagaId);
        if (isCommit)  return implementionWithOSaga.callCommitOnSaga(connection, travelagencyid, sagaId);
        else  return implementionWithOSaga.callRollbackOnSaga(connection, travelagencyid, sagaId);
    }



}

