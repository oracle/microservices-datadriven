CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERYSTATUS VARCHAR2(10),DELIVERYLOCATION VARCHAR2(255)); 
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'teq_UserQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'teq_user', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_UserQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'teq_DelivererQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'teq_deliverer', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_DelivererQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'teq_ApplicationQueue',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'teq_appQueue', 
     queue_payload_type=>'Message_typ', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_ApplicationQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
-- Java TEQ
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'JAVA_TEQ_USER_QUEUE',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'java_user for TEQ', 
     queue_payload_type =>'JMS', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_USER_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'JAVA_TEQ_DELIVERER_QUEUE',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'java_deliverer for TEQ', 
     queue_payload_type =>'JMS', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_DELIVERER_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'JAVA_TEQ_APPLICATION_QUEUE',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'java_appQueue for TEQ', 
     queue_payload_type=>'JMS', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_APPLICATION_QUEUE', enqueue =>TRUE, dequeue=> True); 
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

-- add Subscriber
DECLARE
  subscriber sys.aq$_agent;
BEGIN

--PLSQL: USER Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_UserQueue'       , subscriber => sys.aq$_agent('teq_userAppSubscriber'      , null ,0), rule => 'correlation = ''teq_userAppSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_UserQueue'       , subscriber => sys.aq$_agent('teq_userDelivererSubscriber', null ,0), rule => 'correlation = ''teq_userDelivererSubscriber''');

--PLSQL: Deliverer Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_DelivererQueue'  , subscriber => sys.aq$_agent('teq_delivererUserSubscriber', null ,0), rule => 'correlation = ''teq_delivererUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_DelivererQueue'  , subscriber => sys.aq$_agent('teq_delivererAppSubscriber' , null ,0), rule => 'correlation = ''teq_delivererAppSubscriber''');

--PLSQL: Application Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_ApplicationQueue', subscriber => sys.aq$_agent('teq_appUserSubscriber'      , null ,0), rule => 'correlation = ''teq_appUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_ApplicationQueue', subscriber => sys.aq$_agent('teq_appDelivererSubscriber' , null ,0), rule => 'correlation = ''teq_appDelivererSubscriber''');

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
   -- DBMS_OUTPUT.PUT_LINE ('----------ENQUEUE Message        :  ' || 'ORDERID: ' ||  messageData.ORDERID || ', OTP: ' || messageData.OTP ||', DELIVERYSTATUS: ' || messageData.DELIVERYSTATUS  );  

  
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
    --DBMS_OUTPUT.PUT_LINE ('----------DEQUEUE Message        :  ' || 'ORDERID: ' ||  messageData.ORDERID || ', OTP: ' || messageData.OTP ||', DELIVERYSTATUS: ' || messageData.DELIVERYSTATUS  );  

    RETURN messageData;
END;
/
EXIT;