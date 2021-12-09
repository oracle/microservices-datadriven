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

    String withoutOSaga(Connection connection, String orderid, boolean isCommit) throws SQLException {
        startUpLogicWithoutOSaga(connection);
        String sagaId = implementionWithoutOSaga.beginSaga(connection, orderid);
        implementionWithoutOSaga.logAndAddFlightParticipantToSaga(connection, orderid, sagaId);
        connection.setAutoCommit(false);
        implementionWithoutOSaga.saveFlightInventoryBeforeStateInDevotedInventoryJournalTable(connection, orderid, sagaId);
        implementionWithoutOSaga.reserveFlight(connection, orderid, sagaId);
        connection.commit();
//        implementionWithoutOSaga.addHotelParticipantToSaga(connection, orderid, sagaId);
//        connection.setAutoCommit(false);
//        implementionWithoutOSaga.saveHotelInventoryBeforeStateInDevotedInventoryJournalTable(connection, orderid, sagaId);
//        implementionWithoutOSaga.adjustHotelInventory(connection, orderid, sagaId);
//        connection.commit();
        if (isCommit)  {
            implementionWithoutOSaga.setStateToCommittingOnSaga(connection, orderid, sagaId);
            implementionWithoutOSaga.callCommitOnAllParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.setStateToCommittedOnParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, orderid, sagaId);
            return sagaId;
        }  else  {
            implementionWithoutOSaga.setStateToRollingbackOnSaga(connection, orderid, sagaId);
            implementionWithoutOSaga.callRollbackOnAllParticipants(connection, orderid, sagaId);
            // participants set value back to original based on log
            // participants purge journal tables
            // set state to committed on each participant upon return
            implementionWithoutOSaga.setStateToRolledbackOnParticipants(connection, orderid, sagaId);
            implementionWithoutOSaga.purgeSagaAndParticipantEntries(connection, orderid, sagaId);
            return sagaId;
        }
    }

    //__________________________ WITH OSAGA __________________________

    String withOSaga(Connection connection, String orderid, boolean isCommit)  throws SQLException {
        String sagaId = implementionWithOSaga.beginOSaga(connection, orderid);
//        implementionWithOSaga.reserveHotel(connection, orderid, sagaId);
        if (isCommit)  return implementionWithOSaga.callCommitOnSaga(connection, orderid, sagaId);
        else  return implementionWithOSaga.callRollbackOnSaga(connection, orderid, sagaId);
    }



}

