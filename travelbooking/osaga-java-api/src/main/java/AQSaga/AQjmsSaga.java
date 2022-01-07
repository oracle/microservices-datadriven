/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package AQSaga;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import javax.jms.*;

import AQSaga.wrapper.OracleConnection;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;

/**
 *
 * @author pnavaney
 */
public class AQjmsSaga implements Osaga {

    private final TopicConnection topicConnection;
    private final Session session;
    private MessageConsumer messageConsumer;
    private AQjmsSagaMessageListener listener;

    enum Queuetype {
        IN_QUEUE,
        OUT_QUEUE
    }

    public AQjmsSaga(String hostName, String oracleSID, int portNumber, String driver, String username, String password) throws JMSException {
        this.topicConnection = getTopicConnection(hostName, oracleSID, portNumber, driver, username, password);
        this.session = getTopicSession(this.topicConnection);
        this.topicConnection.start();
    }

    public AQjmsSaga(String jdbcUrl, String username, String password) throws JMSException {
        Properties prop = new Properties();
        prop.setProperty("user", username);
        prop.setProperty("password", password);

        this.topicConnection = getTopicConnection(jdbcUrl, prop, username, password);
        this.session = getTopicSession(this.topicConnection);
        this.topicConnection.start();
    }

    private TopicConnection getTopicConnection(String hostName, String oracleSID, int portNumber, String driver, String username, String password) throws JMSException {

        TopicConnectionFactory topicConnectionFactory = AQjmsFactory.getTopicConnectionFactory(hostName, oracleSID, portNumber, driver);
        return topicConnectionFactory.createTopicConnection(username, password);
    }

    private TopicConnection getTopicConnection(String jdbcUrl, Properties prop, String username, String password) throws JMSException {

        TopicConnectionFactory topicConnectionFactory = AQjmsFactory.getTopicConnectionFactory(jdbcUrl, prop);
        return topicConnectionFactory.createTopicConnection(username, password);
    }

    private Session getTopicSession(TopicConnection connection) throws JMSException {
        return connection.createSession(true, Session.CLIENT_ACKNOWLEDGE);
    }

    public TopicPublisher getSagaOutTopicPublisher(String schema, String participant_name) throws JMSException {
        TopicPublisher outTopicPublisher = null;
        if (session != null) {
            String sagaQueue = getSagaQueue(participant_name, Queuetype.OUT_QUEUE);
            System.out.println("AQjmsSaga.getSagaOutTopicPublisher sagaQueue:" + sagaQueue);
            Topic outTopic = ((AQjmsSession) this.session).getTopic(schema, sagaQueue);
            outTopicPublisher = ((AQjmsSession) this.session).createPublisher(outTopic);
        }
        return outTopicPublisher;
    }

    public void setSagaMessageListener(String schema, String participant, MessageListener sagaListener) throws JMSException {
        setSagaMessageListener(schema, participant, sagaListener, true, false);
    }

    public void setSagaMessageListener(String schema, String participant, MessageListener sagaListener, boolean isReceive) throws JMSException {
        setSagaMessageListener(schema, participant, sagaListener, true, isReceive);
    }

    public void setSagaMessageListener(String schema, String participant, MessageListener sagaListener, boolean createConsumer, boolean isReceive) throws JMSException {
        if (session != null) {
            if (this.messageConsumer == null && createConsumer) {
                Queue inQueue = ((AQjmsSession) this.session).getQueue(schema, getSagaQueue(participant, Queuetype.IN_QUEUE));
                this.messageConsumer = ((AQjmsSession) this.session).createConsumer(inQueue);
            }
            this.listener = (AQjmsSagaMessageListener) sagaListener;
            this.listener.setSession(this.session, getSagaOutTopicPublisher(schema, participant));
            if (createConsumer) {
                this.messageConsumer.setMessageListener(this.listener);
            }
        }
    }

    private String getSagaQueue(String participant, Queuetype type) {
        if (type == Queuetype.IN_QUEUE) {
            return "SAGA$_" + participant + "_IN_Q";
        } else {
            return "SAGA$_" + participant + "_OUT_Q";
        }
    }

    public void enrollParticipant(String sagaId, String schema, String sender, String recipient, String coordinator, String payload) throws JMSException {
        enrollParticipant(sagaId, schema, sender, recipient, coordinator, payload, Constants.DEFAULT_TIMEOUT, Constants.SAGA_V1, null);
    }

    public void enrollParticipant(String sagaId, String schema, String sender, String recipient, String coordinator, String payload, int timeout) throws JMSException {
        enrollParticipant(sagaId, schema, sender, recipient, coordinator, payload, timeout, Constants.SAGA_V1, null);
    }

    public void enrollParticipant(String sagaId, String schema, String sender, String recipient, String coordinator, String payload, int timeout, int version) throws JMSException {
        enrollParticipant(sagaId, schema, sender, recipient, coordinator, payload, timeout, version, null);
    }

    public void enrollParticipant(String sagaId, String schema, String sender, String recipient, String coordinator, String payload, int timeout, int version, String spare) throws JMSException {

        System.out.println("enrollParticipant sagaId = " + sagaId + ", schema = " + schema + ", sender = " + sender +
                ", recipient = " + recipient + ", coordinator = " + coordinator +
                ", payload = " + payload + ", timeout = " + timeout + ", version = " + version + ", spare = " + spare);
        try {
            System.out.println("AQjmsSaga.enrollParticipant call enrollParticipant sproc directly");
            OracleConnection dbConn
                    = new OracleConnection((oracle.jdbc.internal.OracleConnection) ((AQjmsSession) this.session).getDBConnection());
            dbConn.setAutoCommit(false);
            dbConn.enrollParticipant(sagaId, schema, sender, recipient, coordinator);
            this.session.commit();
        } catch (SQLException ex) {
            throw new AQjmsSagaException(ex);
        }


//        System.out.println("AQjmsSaga.enrollParticipant call enrollParticipant message");
        AQjmsTextMessage requestMessage = (AQjmsTextMessage)((AQjmsSession) this.session).createTextMessage();
//        AQSaga.wrapper.AQjmsTextMessage requestMessage = new AQSaga.wrapper.AQjmsTextMessage((AQjmsTextMessage)(session).createTextMessage());
//        requestMessage.setSagaId(sagaId);
        requestMessage.setStringProperty("jms_oracle_aq$_saga_id", sagaId); //may need to convert to byte[] as it's raw type not varchar2
//        requestMessage.setSagaSender(sender);
        requestMessage.setStringProperty("jms_oracle_aq$_saga_sender", sender);
//        requestMessage.setSagaRecipient(recipient);
        requestMessage.setStringProperty("jms_oracle_aq$_saga_recipient", recipient);
//        requestMessage.setSagaCoordinator(coordinator);
        requestMessage.setStringProperty("jms_oracle_aq$_saga_coordinator", coordinator);
//        requestMessage.setSagaOpcode(Constants.OSAGA_REQUEST);
        requestMessage.setIntProperty("jms_oracle_aq$_saga_opcode", Constants.OSAGA_REQUEST);
//        requestMessage.setSagaTimeout(timeout);
//        requestMessage.setStringProperty("jms_oracle_aq$_saga", timeout);
//        requestMessage.setSagaVersion(version);
//        requestMessage.setStringProperty("jms_oracle_aq$_saga", version);
//        requestMessage.setSagaSpare(spare);
//        requestMessage.setStringProperty("jms_oracle_aq$_saga", spare);
//        getSagaOutTopicPublisher(schema, sender).publish(requestMessage);
        this.session.commit();
    }


    @Override
    public String beginSaga(String initiator_name) throws JMSException {
        return beginSaga(initiator_name, Constants.DEFAULT_TIMEOUT, Constants.SAGA_V1);
    }

    @Override
    public String beginSaga(String initiator_name, int timeout) throws JMSException {
        return beginSaga(initiator_name, timeout, Constants.SAGA_V1);
    }

    @Override
    public String beginSaga(String initiator_name, int timeout, int version) throws JMSException {
        
        if(!AQjmsSagaUtils.isSimpleSQLName(initiator_name))
            AQjmsSagaError.throwEx(AQjmsSagaError.SAGA_SIMPLENAMERROR);
        
        byte[] sagaId = null;
        try {
            /* Get Connection */
            OracleConnection dbConn
                    = new OracleConnection((oracle.jdbc.internal.OracleConnection) ((AQjmsSession) this.session).getDBConnection());
            dbConn.setAutoCommit(false);
            sagaId = dbConn.beginSaga(initiator_name, timeout, dbConn.getSchema(), version, 0, 0, 0, null);
            this.session.commit();
        } catch (SQLException ex) {
            throw new AQjmsSagaException(ex);
        }
        return AQjmsSagaUtils.printHexBinary(sagaId);
    }

    @Override
    public void commitSaga(String sagaId, String participant_name) throws JMSException {
        commitOrRollbackSaga(sagaId, participant_name, Constants.OSAGA_COMMIT, true);
    }

    @Override
    public void commitSaga(String sagaId, String participant_name, boolean force) throws JMSException {
        commitOrRollbackSaga(sagaId, participant_name, Constants.OSAGA_COMMIT, force);
    }

    @Override
    public void rollbackSaga(String sagaId, String participant_name) throws JMSException {
        commitOrRollbackSaga(sagaId, participant_name, Constants.OSAGA_ABORT, true);
    }

    @Override
    public void rollbackSaga(String sagaId, String participant_name, boolean force) throws JMSException {
        commitOrRollbackSaga(sagaId, participant_name, Constants.OSAGA_ABORT, force);
    }

    private void commitOrRollbackSaga(String sagaId, String participant_name, int opcode, boolean force) throws JMSException {
        Integer ttc_opcode = null;
        boolean cr_result = true;
        
        if(!AQjmsSagaUtils.isSimpleSQLName(participant_name))
            AQjmsSagaError.throwEx(AQjmsSagaError.SAGA_SIMPLENAMERROR);
        
        participant_name = AQjmsSagaUtils.canonicalize(participant_name);
        
        if(this.listener == null)
            AQjmsSagaError.throwEx(AQjmsSagaError.SAGA_LISTENERNOTFOUND);
        
        try {
            /* Get Connection */
//            oracle.jdbc.internal.OracleConnection dbConn
//                    = (oracle.jdbc.internal.OracleConnection) ((AQjmsSession) this.session).getDBConnection();
            OracleConnection dbConn
                    = new OracleConnection((oracle.jdbc.internal.OracleConnection) ((AQjmsSession) this.session).getDBConnection());
            int saga_status = dbConn.commitRollbackSaga(participant_name, AQjmsSagaUtils.parseHexBinary(sagaId), dbConn.getSchema(), opcode, 0, 0, null);

            if (saga_status == Constants.OSAGA_JOINED) {
                if (opcode == Constants.OSAGA_COMMIT) {
                    this.listener.beforeCommit(sagaId);
                    /* Call escrow TTC here if required */
                    if (cr_result) {
                        ttc_opcode = Constants.OSAGA_COMMIT_SUCCESS;
                    } else {
                        ttc_opcode = Constants.OSAGA_COMMIT_FAIL;
                    }
                    this.listener.afterCommit(sagaId);
                } else if (opcode == Constants.OSAGA_ABORT) {
                    this.listener.beforeRollback(sagaId);
                    if (cr_result) {
                        ttc_opcode = Constants.OSAGA_ABORT_SUCCESS;
                    } else {
                        ttc_opcode = Constants.OSAGA_ABORT_FAIL;
                    }
                    this.listener.afterRollback(sagaId);
                }
                dbConn.commitRollbackSaga(participant_name, AQjmsSagaUtils.parseHexBinary(sagaId), dbConn.getSchema(), ttc_opcode, 0, 0, null);
                this.session.commit();
            }
        } catch (SQLException ex) {
            throw new AQjmsSagaException(ex);
        }
    }

    @Override
    public void forgetSaga(String sagaId) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void leaveSaga(String sagaId) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void afterSaga(String sagaId) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

}
