set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/&1@AQDATABASE_TP ;
/
 --Enqueue to objType Message 
DECLARE
 enqueue_options     dbms_aq.enqueue_options_t;
 message_properties  dbms_aq.message_properties_t;
 message_handle      RAW(16);
 message             Message_type;

BEGIN
 message := Message_type('NORMAL MESSAGE','enqueued to objType_TEQ first.');
 DBMS_AQ.ENQUEUE(
     queue_name           => 'objType_TEQ',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
    COMMIT;
END;
/

 --Enqueue to rawType Message 
DECLARE
 enqueue_options     dbms_aq.enqueue_options_t;
 message_properties  dbms_aq.message_properties_t;
 message_handle      RAW(16);
 message             RAW(4096); 

BEGIN
 message :=  HEXTORAW(RPAD('FF',4095,'FF')); 
 DBMS_AQ.ENQUEUE(
     queue_name           => 'rawType_TEQ',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
    COMMIT;
END;
/
EXIT;