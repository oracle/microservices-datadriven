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
public class AQjmsSagaUtils {

    public static byte byteToHex(byte b) {
        b &= (byte) 0x0F;
        return ((byte) ((b < 10) ? (b + '0') : (b - 10 + 'A')));
    }

    public static String printHexBinary(byte[] sagaId) {
        StringBuilder result = new StringBuilder(sagaId.length * 2);
        for (int i = 0; i < sagaId.length; i++) {
            result.append((char) byteToHex((byte) ((sagaId[i] & 0xF0) >> 4)));
            result.append((char) byteToHex((byte) (sagaId[i] & 0x0F)));
        }
        return result.toString();
    }

    public static byte[] parseHexBinary(String hex) {
        byte[] bArr = new byte[hex.length() / 2];
        int count = 0;
        for (int i = 0; i < hex.length(); i = i + 2) {
            String tempBytes = hex.substring(i, i + 2);
            bArr[count] = (byte) Integer.parseInt(tempBytes, 16);
            count++;
        }
        return bArr;
    }

    public static boolean isSimpleSQLName(String s) throws JMSException{
        s = s.trim();
        
        /* Saga Entities can have max length of 107 */
        if (s.length() == 0 || s.length() > Constants.SAGA_MAX_ENTITY_LEN) {
            AQjmsSagaError.throwEx(AQjmsSagaError.SAGA_MAXLENERROR);
        }

        /* First character should be [a-z][A-Z] */
        if (!Character.isLetter(s.charAt(0))) {
            return false;
        }

        /* Rest of the characters could be alphnumeric or ($,_,#) */
        char ch;
        for (int i = 1; i < s.length(); i++) {
            ch = s.charAt(i);
            if (!Character.isLetterOrDigit(ch) && (ch != '$') && (ch != '_') && (ch != '#')) {
                return false;
            }
        }
        return true;
    }

    public static String canonicalize(String s) {
        boolean isQuoted = false;

        if (s == null) {
            return s;
        }

        if (s.length() >= 2 && s.charAt(0) == '"' && s.charAt(s.length() - 1) == '"') {
            isQuoted = true;
        }

        if (isQuoted) {
            return s.substring(1, s.length() - 1);
        }

        return s.toUpperCase();
    }
}
