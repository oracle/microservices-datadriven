CREATE TYPE Message_typeTEQ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'plsql_UserQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'plsql_user for TEQ', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_UserQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'plsql_DelivererQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'plsql_deliverer for TEQ', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_DelivererQueue', enqueue =>TRUE, dequeue=> True); 
END;
/

BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'plsql_ApplicationQueue',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'plsql_appQueue for TEQ', 
     queue_payload_type=>'Message_typ', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_ApplicationQueue', enqueue =>TRUE, dequeue=> True); 
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
CREATE TABLE USERDETAILSTEQ(
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