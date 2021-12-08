set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;
/
 --Enqueue to objType Message 
DECLARE
 enqueue_options     dbms_aq.enqueue_options_t;
 message_properties  dbms_aq.message_properties_t;
 message_handle      RAW(16);
 message             obj_typ;

BEGIN
 message := message_typ('NORMAL MESSAGE','enqueued to msg_queue first.');
 DBMS_AQ.ENQUEUE(
     queue_name => 'objType_classicQueue',           
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
     queue_name => 'rawType_classicQueue',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
    COMMIT;
END;
/

 --Enqueue to multi consumer rawType Message 
DECLARE
 enqueue_options     dbms_aq.enqueue_options_t;
 message_properties  dbms_aq.message_properties_t;
 message_handle      RAW(16);
 message             RAW(4096); 

BEGIN
 message :=  HEXTORAW(RPAD('FF',4095,'FF')); 
 DBMS_AQ.ENQUEUE(
     queue_name           => 'multiconsumer_rawType_classicQueue',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
    COMMIT;
END;
/
EXIT;