
--Dequeue from obj Type Messages */ 
DECLARE
    dequeue_options     dbms_aq.dequeue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             obj_typ;

BEGIN
    DBMS_AQ.DEQUEUE(
        queue_name         => 'objType_AQ',
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
    DBMS_AQ.DEQUEUE(
        queue_name         => 'rawType_AQ', 
        dequeue_options    => dequeue_options, 
        message_properties => message_properties, 
        payload            => message, 
        msgid              => message_handle); 
    COMMIT; 
END;
/

--Dequeue from multiconsumer RAW Type Messages */ 
DECLARE 
    dequeue_options     DBMS_AQ.dequeue_options_t; 
    message_properties  DBMS_AQ.message_properties_t; 
    message_handle      RAW(16); 
    message             RAW(4096); 
        
BEGIN 
    dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name := 'basicSubscriber';

    DBMS_AQ.DEQUEUE(
        queue_name         => 'multiconsumer_rawType_AQ', 
        dequeue_options    => dequeue_options, 
        message_properties => message_properties, 
        payload            => message, 
        msgid              => message_handle); 
    COMMIT; 
END;
/
EXIT;