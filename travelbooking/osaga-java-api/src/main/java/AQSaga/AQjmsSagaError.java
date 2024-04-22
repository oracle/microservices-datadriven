/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package AQSaga;

import java.text.MessageFormat;
import java.util.ResourceBundle;
import javax.jms.JMSException;

/**
 *
 * @author pnavaney
 */
public class AQjmsSagaError {

    private static ResourceBundle bundle;
    public static final int SAGA_MAXLENERROR = 258;
    public static final int SAGA_SIMPLENAMERROR = 259;
    public static final int SAGA_LISTENERNOTFOUND = 260;
            
    static String getMessage(String key, Object[] args) {

        String ret_string = null;
        if (bundle == null) {
            bundle = ResourceBundle.getBundle("oracle.jms.AQjmsMessages");
        }

        try {
            ret_string = MessageFormat.format(bundle.getString(key), args);
            ret_string = "JMS-" + key + ": " + ret_string;
        } catch (Exception e) {
            ret_string = "Message [" + key + "] not found";
        }

        return ret_string;
    }

    static void throwEx(int jms_error_code) throws JMSException {
        String msg = null;
        String args[] = new String[2];

        args[0] = "";
        args[1] = "";

        msg = AQjmsSagaError.getMessage(Integer.toString(jms_error_code), args);

        throw new AQjmsSagaException(msg, jms_error_code);
    }
}
