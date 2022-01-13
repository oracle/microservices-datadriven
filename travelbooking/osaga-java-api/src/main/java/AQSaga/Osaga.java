/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package AQSaga;

import javax.jms.JMSException;

/**
 *
 * @author pnavaney
 */

public interface Osaga {
    
    public String beginSaga(String initiator_name) throws JMSException;
    
    public String beginSaga(String initiator_name, int timeout) throws JMSException;
    
    public String beginSaga(String initiator_name, int timeout, int version) throws JMSException;
    
    public void rollbackSaga(String sagaId, String participant_name) throws JMSException;
    
    public void rollbackSaga(String sagaId, String participant_name, boolean force) throws JMSException;

    public void commitSaga(String sagaId, String participant_name, boolean force) throws JMSException;
    
    public void commitSaga(String sagaId, String participant_name) throws JMSException;
    
    public void forgetSaga(String sagaId);

    public void leaveSaga(String sagaId);

    public void afterSaga(String sagaId);
    
}
