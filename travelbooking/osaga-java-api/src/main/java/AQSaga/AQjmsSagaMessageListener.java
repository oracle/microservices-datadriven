/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package AQSaga;

import java.sql.SQLException;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageListener;
import javax.jms.Session;
import javax.jms.TopicPublisher;

import AQSaga.wrapper.OracleConnection;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;

public abstract class AQjmsSagaMessageListener implements MessageListener {

    private Session session;
    private TopicPublisher outTopicPublisher;

    @Override
    public final void onMessage(Message message) {
        log("AQjmsSagaMessageListener.onMessage message:" + message);
        AQjmsTextMessage msg = (AQjmsTextMessage)message;
        try {

            String sagaId =  msg.getStringProperty("jms_oracle_aq$_saga_id");// msg.getSagaId();
            Integer opcode = msg.getIntProperty("jms_oracle_aq$_saga_opcode"); //msg.getSagaOpcode();
            String recipient = msg.getStringProperty("jms_oracle_aq$_saga_recipient");// msg.getSagaRecipient();
            String coordinator = msg.getStringProperty("jms_oracle_aq$_saga_coordinator");// msg.getSagaCoordinator();
            String sender = msg.getStringProperty("jms_oracle_aq$_saga_sender");// msg.getSagaSender();
            String payload = msg.getText();
            Integer timeout = Constants.DEFAULT_TIMEOUT;// msg.getSagaTimeout() == null ? Constants.DEFAULT_TIMEOUT : msg.getSagaTimeout();
            Integer version = Constants.SAGA_V1;// msg.getSagaVersion() == null ? Constants.SAGA_V1 : msg.getSagaVersion();
            String spare = "";// msg.getSagaSpare();
            log("AQjmsSagaMessageListener.onMessage sagaId:" + sagaId);
            log("AQjmsSagaMessageListener.onMessage opcode:" + opcode);
            log("AQjmsSagaMessageListener.onMessage recipient:" + recipient);
            log("AQjmsSagaMessageListener.onMessage coordinator:" + coordinator);
            log("AQjmsSagaMessageListener.onMessage sender:" + sender);
            log("AQjmsSagaMessageListener.onMessage payload:" + payload);
            if (sagaId != null && !sagaId.isEmpty()) {
                String response = null;
                OracleConnection dbConn
                        = new OracleConnection((oracle.jdbc.internal.OracleConnection)((AQjmsSession) this.session).getDBConnection());
                dbConn.setAutoCommit(false);
                /**
                 JOIN_SAGA CONSTANT NUMBER := 0;
                 CMT_SAGA CONSTANT NUMBER := 1;
                 ABRT_SAGA CONSTANT NUMBER := 2;


                 RESPONSE CONSTANT NUMBER := 5;
                 CMT_FAIL CONSTANT NUMBER := 6;
                 ABRT_FAIL CONSTANT NUMBER := 7;
                 */
                switch (opcode) {
                    case 4: //  REQUEST CONSTANT NUMBER := 4;
                        //todo parse annotation on this.getClass().get (String request(String sagaId, String payload); method) and act accordingly
                        int sagaStatus = joinSaga(dbConn, sagaId, recipient, sender, coordinator, timeout, version, payload);
                        log("AQjmsSagaMessageListener.onMessage sagaStatus == Constants.JOIN_EXISTS sendMessage with response");
                        //todo add this back for the case where join already exists ...
//                        if (sagaStatus == Constants.JOIN_EXISTS) {
//                            log("AQjmsSagaMessageListener.onMessage sagaStatus == Constants.JOIN_EXISTS sendMessage with response");
//                            response = request(sagaId, payload);
//                            sendMessage(sagaId, recipient, sender, coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
//                        }
                        break;
                    case 3: // ACK_SAGA CONSTANT NUMBER := 3;
                        log("ACK_SAGA received, updating status to joined...");
                        dbConn.updateStatusToJoined(sagaId, recipient, sender, coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
                        log("ACK_SAGA received, getting response...");
                        response = request(sagaId, payload);
                        log("ACK_SAGA received, about to send response:" + response);
                        sendMessage(sagaId, recipient, sender, coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
                        log("ACK_SAGA received, response sent");
                        break;
                    case 1: // Constants.OSAGA_COMMIT:
                        commitOrRollbackSaga(dbConn, recipient, sagaId, Constants.OSAGA_COMMIT_NTFN, true);
                        break;
                    case 2: // Constants.OSAGA_ABORT:
                        commitOrRollbackSaga(dbConn, recipient, sagaId, Constants.OSAGA_ABORT_NTFN, true);
                        break;
                    case 5: // Constants.OSAGA_RESPONSE:
                        response(sagaId, payload);
                        break;
                }
            }
            log("AQjmsSagaMessageListener.about to commit session");
            this.session.commit();
            log("AQjmsSagaMessageListener session committed");
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    void setSession(Session session, TopicPublisher outTopicPublisher) {
        this.session = session;
        this.outTopicPublisher = outTopicPublisher;
    }

    private int joinSaga(OracleConnection dbConn, String sagaId, String recipient, String sender,
                         String coordinator, int timeout, int saga_version, String payload) throws JMSException {
        try {
            int sagaStatus = dbConn.joinSaga(recipient, AQjmsSagaUtils.parseHexBinary(sagaId), coordinator, sender, timeout, saga_version, Constants.OSAGA_JOIN, 0, 0, null);
            /* Check the saga status before requesting an ACK from the coordinator */
            log("AQjmsSagaMessageListener.joinSaga sagaStatus:" + sagaStatus);
            if (sagaStatus == Constants.OSAGA_JOINED) { //joined is 0
                return Constants.JOIN_EXISTS;
            } else if (sagaStatus != Constants.OSAGA_NEW) {
                return Constants.JOIN_SKIP;
            }
            /* Request an ACK from the coordinator */
//            sendMessage(sagaId, recipient, coordinator, coordinator, Constants.OSAGA_JOIN, timeout, saga_version, sender, payload);
            /* Update sys.saga$ locally */
//            dbConn.joinSaga(recipient, AQjmsSagaUtils.parseHexBinary(sagaId), coordinator, sender, timeout, saga_version, Constants.OSAGA_BEGIN, 0, 0, null);
            this.session.commit();
        } catch (SQLException ex) {
            throw new AQjmsSagaException(ex);
        }
        return Constants.JOIN_SUCCESS;
    }

    private void commitOrRollbackSaga(OracleConnection dbConn, String participant_name, String sagaId, int opcode, boolean force) throws JMSException {
        Integer ttc_opcode = null;
        boolean cr_result = true;
        try {
            int saga_status = dbConn.commitRollbackSaga(participant_name, AQjmsSagaUtils.parseHexBinary(sagaId), dbConn.getSchema(), opcode, 0, 0, null);
            if (saga_status == Constants.OSAGA_JOINED) {
                if (opcode == Constants.OSAGA_COMMIT_NTFN) {
                    beforeCommit(sagaId);
                    /* Call escrow TTC here if required */
                    if (cr_result) {
                        ttc_opcode = Constants.OSAGA_COMMIT_SUCCESS;
                    } else {
                        ttc_opcode = Constants.OSAGA_COMMIT_FAIL;
                    }
                    afterCommit(sagaId);
                } else if (opcode == Constants.OSAGA_ABORT_NTFN) {
                    beforeRollback(sagaId);
                    if (cr_result) {
                        ttc_opcode = Constants.OSAGA_ABORT_SUCCESS;
                    } else {
                        ttc_opcode = Constants.OSAGA_ABORT_FAIL;
                    }
                    afterRollback(sagaId);
                }
                dbConn.commitRollbackSaga(participant_name, AQjmsSagaUtils.parseHexBinary(sagaId), dbConn.getSchema(), ttc_opcode, 0, 0, null);
                this.session.commit();
            }
        } catch (SQLException ex) {
            throw new AQjmsSagaException(ex);
        }
    }

    /* We can decide later what format we want to send over */
    private void sendMessage(String sagaId, String sender, String recipient, String coordinator, int opcode,
            int timeout, int version, String spare, String payload) throws JMSException {
        AQSaga.wrapper.AQjmsTextMessage responseMessage = new AQSaga.wrapper.AQjmsTextMessage((AQjmsTextMessage) ((AQjmsSession) this.session).createTextMessage());
        responseMessage.setSagaId(sagaId);
        responseMessage.setSagaSender(sender);
        responseMessage.setSagaRecipient(recipient);
        responseMessage.setSagaCoordinator(coordinator);
        responseMessage.setSagaOpcode(opcode);
        responseMessage.setSagaVersion(version);
        responseMessage.setSagaTimeout(timeout);
        responseMessage.setSagaSpare(spare);
        responseMessage.setText(payload);
        this.outTopicPublisher.publish(responseMessage.getTextMessage());
        this.session.commit();
    }

    public abstract String request(String sagaId, String payload);

    public abstract void response(String sagaId, String payload);

    public abstract void beforeCommit(String sagaId);

    public abstract void afterCommit(String sagaId);

    public abstract void beforeRollback(String sagaId);

    public abstract void afterRollback(String sagaId);

    
    void log(String msg) {
        System.out.println("AQjmsSagaMessageListener:" + msg);
    }
}
