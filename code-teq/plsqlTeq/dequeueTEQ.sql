--Dequeue from obj Type Messages */ 
DECLARE
    dequeue_options     dbms_aq.dequeue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             Message_type;

BEGIN
    dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name := 'teqBasicObjSubscriber';

    DBMS_AQ.DEQUEUE(
        queue_name         => 'objType_TEQ',
        dequeue_options    => dequeue_options,
        message_properties => message_properties,
        payload            => message,
        msgid              => message_handle);
        
    DBMS_OUTPUT.PUT_LINE ('Message: ' || message.subject || ' ... ' || message.text );
    COMMIT;
END;
/

--Dequeue from RAW Type Messages */ 
DECLARE 
    dequeue_options     DBMS_AQ.dequeue_options_t; 
    message_properties  DBMS_AQ.message_properties_t; 
    message_handle      RAW(16); 
    message             RAW(4096); 
        
BEGIN 
 dequeue_options.dequeue_mode     := DBMS_AQ.REMOVE;
    dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name := 'teqBasicRawSubscriber';

    DBMS_AQ.DEQUEUE(
        queue_name         => 'rawType_TEQ', 
        dequeue_options    => dequeue_options, 
        message_properties => message_properties, 
        payload            => message, 
        msgid              => message_handle); 
    COMMIT; 
END;
/

--Dequeue from JSON TEQ
DECLARE
    dequeue_options     dbms_aq.dequeue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             JSON;

BEGIN
    dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name := 'teqBasicJsonSubscriber';

DBMS_AQ.DEQUEUE(
        queue_name         => 'jsonType_TEQ',
        dequeue_options    => dequeue_options,
        message_properties => message_properties,
        payload            => message,
        msgid              => message_handle);
  dbms_output.put_line(json_serialize(message));
 COMMIT;
END;
/
EXIT;