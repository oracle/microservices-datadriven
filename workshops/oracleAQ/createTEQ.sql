
CREATE type Message_type as object (subject     VARCHAR2(30), text        VARCHAR2(80));  
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'objType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'ObjectType for TEQ', 
     queue_payload_type =>'Message_type', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'objType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/

-- Creating a RAW type queue: 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'rawType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'RAW type for TEQ', 
     queue_payload_type =>'RAW', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'rawType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/

--Creating JSON type queue:
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'jsonType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'jsonType for TEQ', 
     queue_payload_type =>'JSON', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'jsonType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'JAVA_TEQ_PUBSUB_QUEUE',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'JAVA_TEQ_PUBSUB_QUEUE', 
     queue_payload_type=>'JMS', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_PUBSUB_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
dbms_aqadm.add_subscriber(queue_name => 'objType_TEQ'       , subscriber => sys.aq$_agent('teqBasicObjSubscriber'      , null ,0), rule => 'correlation = ''teqBasicObjSubscriber''');

dbms_aqadm.add_subscriber(queue_name => 'rawType_TEQ'       , subscriber => sys.aq$_agent('teqBasicRawSubscriber'      , null ,0), rule => 'correlation = ''teqBasicRawSubscriber''');

dbms_aqadm.add_subscriber(queue_name => 'jsonType_TEQ'       , subscriber => sys.aq$_agent('teqBasicJsonSubscriber'      , null ,0), rule => 'correlation = ''teqBasicJsonSubscriber''');

END;
/
CREATE OR REPLACE FUNCTION enqueueDequeueTEQ(subscriber varchar2, queueName varchar2, message Message_Typ) RETURN Message_Typ 
IS 
    enqueue_options                   DBMS_AQ.enqueue_options_t;
    message_properties                DBMS_AQ.message_properties_t;
    message_handle                    RAW(16);
    dequeue_options                   DBMS_AQ.dequeue_options_t;
    messageData                       Message_Typ;

BEGIN
    messageData                       := message;
    message_properties.correlation := subscriber;
    DBMS_AQ.ENQUEUE(
        queue_name                    => queueName,           
        enqueue_options               => enqueue_options,       
        message_properties            => message_properties,     
        payload                       => messageData,               
        msgid                         => message_handle);
        COMMIT;
    DBMS_OUTPUT.PUT_LINE ('----------ENQUEUE Message:  ' || 'ORDERID: ' ||  messageData.ORDERID || ', OTP: ' || messageData.OTP ||', DELIVERY_STATUS: ' || messageData.DELIVERY_STATUS  );  
  
    dequeue_options.dequeue_mode      := DBMS_AQ.REMOVE;
    dequeue_options.wait              := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation        := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name     := subscriber;
    DBMS_AQ.DEQUEUE(
        queue_name                    => queueName,
        dequeue_options               => dequeue_options, 
        message_properties            => message_properties, 
        payload                       => messageData, 
        msgid                         => message_handle);
        COMMIT;
    DBMS_OUTPUT.PUT_LINE ('----------DEQUEUE Message:  ' || 'ORDERID: ' ||  messageData.ORDERID || ', OTP: ' || messageData.OTP ||', DELIVERY_STATUS: ' || messageData.DELIVERY_STATUS  );  
    RETURN messageData;
END;
/
EXIT;      