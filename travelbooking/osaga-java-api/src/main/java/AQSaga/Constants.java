package AQSaga;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author pnavaney
 */
public class Constants {
    /* Timeout */
    public static final int DEFAULT_TIMEOUT = 86400;
    
    /* Saga Versions */
    public static final int SAGA_V1 = 1;
    
    /* Lengths */
    public static final int SAGA_MAX_ENTITY_LEN = 107;
    public static final int SAGA_MAX_ENTITY_LEN_Q = 109;
    public static final int SAGA_MAX_LEN = 128;
    
    /* Opcodes */
    public static final int OSAGA_BEGIN = 0;
    public static final int OSAGA_JOIN = 1;
    public static final int OSAGA_COMMIT = 2;
    public static final int OSAGA_COMMIT_NTFN = 3;
    public static final int OSAGA_ABORT = 4;
    public static final int OSAGA_ABORT_NTFN = 5;
    public static final int OSAGA_ACK = 6;
    public static final int OSAGA_REQUEST = 7;
    public static final int OSAGA_RESPONSE = 8;
    public static final int OSAGA_COMMIT_FAIL = 9;
    public static final int OSAGA_ABORT_FAIL = 10;
    public static final int OSAGA_COMMIT_SUCCESS = 11;
    public static final int OSAGA_ABORT_SUCCESS = 12;
    
    /* Join Status */
    public static final int JOIN_EXISTS = -1;
    public static final int JOIN_SUCCESS = 0;
    public static final int JOIN_SKIP = 1;
    
    /* Saga Status */
    public static final int OSAGA_NEW = -2;
    public static final int OSAGA_JOINING = -1;
    public static final int OSAGA_INITIATED = 0;
    public static final int OSAGA_JOINED = 0;
    public static final int OSAGA_FINALIZATION = 1;
    public static final int OSAGA_COMMITED = 2;
    public static final int OSAGA_ROLLEDBACK = 3;
    public static final int OSAGA_COMMIT_FAILED = 4;
    public static final int OSAGA_ABORT_FAILED = 5;
}
