/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package AQSaga;

import java.sql.SQLException;
import javax.jms.JMSException;

/**
 *
 * @author pnavaney
 */
public class AQjmsSagaException extends JMSException {

    AQjmsSagaException(String message, int ora_error_code) {
        super(message, Integer.toString(ora_error_code));
    }

    public AQjmsSagaException(SQLException ex) {
        super(ex.getMessage(), Integer.toString(ex.getErrorCode()));
        this.setLinkedException(ex);
        this.initCause(ex);
    }

}
