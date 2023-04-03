--Enqueue to objType Message 
DECLARE
 enqueue_options     dbms_aq.enqueue_options_t;
 message_properties  dbms_aq.message_properties_t;
 message_handle      RAW(16);
 message             Message_type;

BEGIN
 message := Message_type('NORMAL MESSAGE','enqueue objType_TxEventQ');
 message_properties.correlation := 'TxEventQBasicObjSubscriber';

 DBMS_AQ.ENQUEUE(
     queue_name           => 'objType_TxEventQ',           
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
 message_properties.correlation := 'TxEventQBasicRawSubscriber';

 DBMS_AQ.ENQUEUE(
     queue_name           => 'rawType_TxEventQ',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
    COMMIT;
END;
/
-- Enqueue for JSON Message
DECLARE
enqueue_options    dbms_aq.enqueue_options_t;
message_properties dbms_aq.message_properties_t;
message_handle     RAW(16);
message            json;
BEGIN
  message:= json('
        {
        "ORDERID":12345, 
        "USERNAME":"name"  
        }');
  message_properties.correlation := 'TxEventQBasicJsonSubscriber';

DBMS_AQ.ENQUEUE(
     queue_name           => 'jsonType_TxEventQ',           
     enqueue_options      => enqueue_options,       
     message_properties   => message_properties,     
     payload              => message,               
     msgid                => message_handle);
   dbms_output.put_line(json_serialize(message));
   COMMIT;
END;
/
EXIT;