package AQSaga.wrapper;


import javax.jms.Message;
import javax.jms.TextMessage;

public class AQjmsTextMessage extends  oracle.jms.AQjmsTextMessage {
    oracle.jms.AQjmsTextMessage aqjmsTextMessage;
            
    public AQjmsTextMessage(oracle.jms.AQjmsTextMessage textMessage) {
        super();
        aqjmsTextMessage = textMessage;
    }

    public void setSagaId(String sagaId) {
    }

    public void setSagaSender(String sender) {
    }

    public void setSagaRecipient(String recipient) {
    }

    public void setSagaCoordinator(String coordinator) {
    }

    public void setSagaOpcode(int osagaRequest) {
    }

    public void setSagaTimeout(int timeout) {
    }

    public void setSagaVersion(int version) {
    }

    public void setSagaSpare(String spare) {
    }

    public Message getTextMessage() {
        return aqjmsTextMessage;
    }

    public String getSagaId() {
        return "";
    }

    public Integer getSagaOpcode() {
        return 0;
    }

    public String getSagaRecipient() {
        return "";
    }

    public String getSagaCoordinator() {
        return "";
    }

    public String getSagaSender() {
        return "";
    }

    public String getText() {
        return "";
    }

    public Integer getSagaTimeout() {
        return 0;
    }

    public Integer getSagaVersion() {
        return 0;
    }

    public String getSagaSpare() {
        return "";
    }

    public void setText(String payload) {
    }
}
