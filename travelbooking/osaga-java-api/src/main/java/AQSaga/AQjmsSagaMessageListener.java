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
        log("------------- Enter AQjmsSagaMessageListener.onMessage message:" + message + " -------------");
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
            log("AQjmsSagaMessageListener.onMessage opcode String:" + getOpStringForOpCode(opcode));
            log("AQjmsSagaMessageListener.onMessage recipient:" + recipient);
            log("AQjmsSagaMessageListener.onMessage coordinator:" + coordinator);
            log("AQjmsSagaMessageListener.onMessage sender:" + sender);
            log("AQjmsSagaMessageListener.onMessage payload:" + payload);
            if (sagaId != null && !sagaId.isEmpty()) {
                String response = null;
                OracleConnection dbConn
                        = new OracleConnection((oracle.jdbc.internal.OracleConnection)((AQjmsSession) this.session).getDBConnection());
                dbConn.setAutoCommit(false);
                switch (opcode) {
                    case 4: //  REQUEST
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
                    case 3: // ACK_SAGA
                        log("ACK_SAGA received, updating status to joined...");
                        dbConn.updateStatusToJoined(sagaId, recipient, sender, coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
                        log("ACK_SAGA received, getting response...");
                        response = request(sagaId, payload);
                        log("ACK_SAGA received, about to send response:" + response);
                        //get iniator from select and use it as sender
                        sendMessage(sagaId, recipient, "TRAVELAGENCYJAVA", coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
//                        sendMessage(sagaId, recipient, sender, coordinator, Constants.OSAGA_RESPONSE, timeout, version, null, response);
                        log("ACK_SAGA received, response sent");
                        break;
                    case 1: // OSAGA_COMMIT
                        afterCommit(sagaId);
                        break;
                    case 2: // OSAGA_ABORT
                        afterRollback(sagaId);
                        break;
                    case 5: // OSAGA_RESPONSE
                        response(sagaId, payload);
                        break;
                }
            }
            this.session.commit();
            log("------------- Exit AQjmsSagaMessageListener.onMessage message:" + message + " -------------");
        } catch (Exception ex) {
            ex.printStackTrace();
            if (session !=null) {
                try {
                    this.session.rollback();
                } catch (JMSException e) {
                    System.out.println("AQjmsSagaMessageListener.onMessage failed attempting to rollback session after exception");
                    e.printStackTrace();
                }
            }
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
        log("publishing to outTopicPublisher:" + outTopicPublisher + " sagaId = " + sagaId + ", sender = " + sender +
                ", recipient = " + recipient + ", coordinator = " + coordinator +
                ", opcode = " + opcode + ", timeout = " + timeout + ", version = " + version +
                ", spare = " + spare + ", payload = " + payload);
        this.outTopicPublisher.publish(responseMessage.getrequestMessage());
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

    String getOpStringForOpCode(int opCode) {
        switch (opCode) {
            case 0:
                return "JOIN_SAGA";
            case 1:
                return "CMT_SAGA";
            case 2:
                return "ABRT_SAGA";
            case 3:
                return "ACK_SAGA";
            case 4:
                return "REQUEST";
            case 5:
                return "RESPONSE";
            case 6:
                return "CMT_FAIL";
            case 7:
                return "ABRT_FAIL";
            default:
                return "Unknown opCode:" + opCode;
        }
    }
}
