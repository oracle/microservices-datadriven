CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERYSTATUS VARCHAR2(10),DELIVERYLOCATION VARCHAR2(255)); 
/
-- Creating a Multiconsumer object type queue table and queue */
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_UserQueueTable',      queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_UserQueue',           queue_table         => 'aq_UserQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_UserQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_DelivererQueueTable',   queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_DelivererQueue',        queue_table         => 'aq_DelivererQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_DelivererQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_ApplicationQueueTable', queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_ApplicationQueue',      queue_table         => 'aq_ApplicationQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_ApplicationQueue'); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN

--PLSQL: USER Subscriber
dbms_aqadm.add_subscriber(queue_name => 'aq_UserQueue'       , subscriber => sys.aq$_agent('aq_userAppSubscriber'      , null ,0));
dbms_aqadm.add_subscriber(queue_name => 'aq_UserQueue'       , subscriber => sys.aq$_agent('aq_userDelivererSubscriber', null ,0));

--PLSQL: Deliverer Subscriber
dbms_aqadm.add_subscriber(queue_name => 'aq_DelivererQueue'  , subscriber => sys.aq$_agent('aq_delivererUserSubscriber', null ,0));
dbms_aqadm.add_subscriber(queue_name => 'aq_DelivererQueue'  , subscriber => sys.aq$_agent('aq_delivererAppSubscriber' , null ,0));

--PLSQL: Application Subscriber
dbms_aqadm.add_subscriber(queue_name => 'aq_ApplicationQueue', subscriber => sys.aq$_agent('aq_appUserSubscriber'      , null ,0));
dbms_aqadm.add_subscriber(queue_name => 'aq_ApplicationQueue', subscriber => sys.aq$_agent('aq_appDelivererSubscriber' , null ,0));

END;
/
CREATE TABLE USERDETAILS(
    ORDERID number(10), 
    USERNAME varchar2(255), 
    OTP number(4), 
    DELIVERYSTATUS varchar2(10),
    DELIVERYLOCATION varchar2(255),
    primary key(ORDERID)
);
/
CREATE OR REPLACE FUNCTION enqueueDequeueAQ(subscriber varchar2, queueName varchar2, message Message_Typ) RETURN Message_Typ 
IS 
    enqueue_options                   DBMS_AQ.enqueue_options_t;
    message_properties                DBMS_AQ.message_properties_t;
    message_handle                    RAW(16);
    recipients                        DBMS_AQ.aq$_recipient_list_t;
    dequeue_options                   DBMS_AQ.dequeue_options_t;
    messageData                       Message_Typ;

BEGIN
    messageData                       := message;
    recipients(1)                     := sys.aq$_agent(subscriber, NULL, NULL);
    message_properties.recipient_list := recipients;    
    DBMS_AQ.ENQUEUE(
        queue_name                    => queueName,           
        enqueue_options               => enqueue_options,       
        message_properties            => message_properties,     
        payload                       => messageData,               
        msgid                         => message_handle);
        COMMIT;
    --DBMS_OUTPUT.PUT_LINE ('----------ENQUEUE Message        :  ' || 'ORDERID: ' ||  messageData.ORDERID || ', OTP: ' || messageData.OTP ||', DELIVERYSTATUS: ' || messageData.DELIVERYSTATUS  );  

  
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