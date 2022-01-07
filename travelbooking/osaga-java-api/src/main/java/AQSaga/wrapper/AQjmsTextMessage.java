package AQSaga.wrapper;


import AQSaga.Constants;

import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.TextMessage;

public class AQjmsTextMessage extends  oracle.jms.AQjmsTextMessage {
    oracle.jms.AQjmsTextMessage requestMessage;
            
    public AQjmsTextMessage(oracle.jms.AQjmsTextMessage textMessage) {
        super();
        requestMessage = textMessage;
    }

    public oracle.jms.AQjmsTextMessage getrequestMessage() {
        return requestMessage;
    }

    @Override
    public void setText(String s) throws JMSException {
        requestMessage.setText(s);
    }

    public void setSagaId(String sagaId) throws JMSException {
        requestMessage.setStringProperty("jms_oracle_aq$_saga_id", sagaId);
    }

    public void setSagaSender(String sender)  throws JMSException {
        requestMessage.setStringProperty("jms_oracle_aq$_saga_sender", sender);
    }

    public void setSagaRecipient(String recipient) throws JMSException {
        requestMessage.setStringProperty("jms_oracle_aq$_saga_recipient", recipient);
    }

    public void setSagaCoordinator(String coordinator) throws JMSException {
        requestMessage.setStringProperty("jms_oracle_aq$_saga_coordinator", coordinator);
    }

    public void setSagaOpcode(int osagaRequest) throws JMSException {
        requestMessage.setIntProperty("jms_oracle_aq$_saga_opcode", osagaRequest );
    }

    public void setSagaTimeout(int timeout) throws JMSException {
        requestMessage.setIntProperty("jms_oracle_aq$_saga_timeout", timeout );
    }

    public void setSagaVersion(int version)  throws JMSException {
        requestMessage.setIntProperty("jms_oracle_aq$_saga_version", version );
    }

    public void setSagaSpare(String spare) throws JMSException {
        requestMessage.setStringProperty("jms_oracle_aq$_saga_spare", spare);
    }

    public Message getTextMessage() {
        return requestMessage;
    }

    public String getSagaId() throws JMSException {
        return requestMessage.getStringProperty("jms_oracle_aq$_saga_id");
    }

    public Integer getSagaOpcode() throws JMSException {
        return requestMessage.getIntProperty("jms_oracle_aq$_saga_opcode");
    }

    public String getSagaRecipient() throws JMSException {
        return requestMessage.getStringProperty("jms_oracle_aq$_saga_recipient");
    }

    public String getSagaCoordinator() throws JMSException {
        return requestMessage.getStringProperty("jms_oracle_aq$_saga_coordinator");
    }

    public String getSagaSender() throws JMSException {
        return requestMessage.getStringProperty("jms_oracle_aq$_saga_recipient");
    }


    public Integer getSagaTimeout() throws JMSException {
        return requestMessage.getIntProperty("jms_oracle_aq$_saga_timeout");
    }

    public Integer getSagaVersion() throws JMSException {
        return requestMessage.getIntProperty("jms_oracle_aq$_saga_version");
    }

    public String getSagaSpare() throws JMSException {
        return requestMessage.getStringProperty("jms_oracle_aq$_saga_spare");
    }

}
