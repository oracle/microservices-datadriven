CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
/
-- Creating a Multiconsumer object type queue table and queue */
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_UserQueueTable',      queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'plsql_UserQueue',           queue_table         => 'plsql_UserQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'plsql_UserQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_DelivererQueueTable',   queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'plsql_DelivererQueue',        queue_table         => 'plsql_DelivererQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'plsql_DelivererQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_ApplicationQueueTable', queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'plsql_ApplicationQueue',      queue_table         => 'plsql_ApplicationQueueTable');  
 DBMS_AQADM.START_QUEUE        ( queue_name     => 'plsql_ApplicationQueue'); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
--user Subscriber
  subscriber := sys.aq$_agent('plsql_userAppSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_UserQueue', subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_userDelivererSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_UserQueue', subscriber => subscriber);

--Deliverer Subscriber
  subscriber := sys.aq$_agent('plsql_delivererUserSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_DelivererQueue', subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_delivererApplicationSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_DelivererQueue', subscriber => subscriber);

--Application Subscriber
  subscriber := sys.aq$_agent('plsql_appUserSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_ApplicationQueue', subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_appDelivererSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER  (queue_name => 'plsql_ApplicationQueue', subscriber => subscriber);
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