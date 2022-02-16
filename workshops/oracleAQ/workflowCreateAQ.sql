CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
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
dbms_aqadm.add_subscriber(queue_name => 'aq_UserQueue'       , subscriber => sys.aq$_agent('aq_userAppSubscriber'      , null ,0), rule => 'correlation = ''aq_userAppSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'aq_UserQueue'       , subscriber => sys.aq$_agent('aq_userDelivererSubscriber', null ,0), rule => 'correlation = ''aq_userDelivererSubscriber''');

--PLSQL: Deliverer Subscriber
dbms_aqadm.add_subscriber(queue_name => 'aq_DelivererQueue'  , subscriber => sys.aq$_agent('aq_delivererUserSubscriber', null ,0), rule => 'correlation = ''aq_delivererUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'aq_DelivererQueue'  , subscriber => sys.aq$_agent('aq_delivererAppSubscriber' , null ,0), rule => 'correlation = ''aq_delivererAppSubscriber''');

--PLSQL: Application Subscriber
dbms_aqadm.add_subscriber(queue_name => 'aq_ApplicationQueue', subscriber => sys.aq$_agent('aq_appUserSubscriber'      , null ,0), rule => 'correlation = ''aq_appUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'aq_ApplicationQueue', subscriber => sys.aq$_agent('aq_appDelivererSubscriber' , null ,0), rule => 'correlation = ''aq_appDelivererSubscriber''');

END;
/
CREATE TABLE USERDETAILS(
    ORDERID number(10), 
    USERNAME varchar2(255), 
    OTP number(4), 
    DELIVERY_STATUS varchar2(10),
    DELIVERY_LOCATION varchar2(255),
    primary key(ORDERID)
);
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;