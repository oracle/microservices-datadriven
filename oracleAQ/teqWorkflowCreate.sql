CREATE TYPE Message_typeTEQ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'plsql_userTEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'plsql_user for TEQ', 
     queue_payload_type =>'Message_typeTEQ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_userTEQ', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'plsql_deliveryTEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'plsql_delivery for TEQ', 
     queue_payload_type =>'Message_typeTEQ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_deliveryTEQ', enqueue =>TRUE, dequeue=> True); 
END;
/

BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'plsql_appTEQ',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'plsql_appQueue for TEQ', 
     queue_payload_type=>'Message_typeTEQ', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'plsql_appTEQ', enqueue =>TRUE, dequeue=> True); 
END;
/
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
  subscriber := sys.aq$_agent('plsql_userSubscriberTEQ', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_userTEQ',subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_deliverySubscriberTEQ', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_deliveryTEQ',subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_appSubscriberTEQ', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_appTEQ',subscriber => subscriber);
END;
/
-- CREATE TABLE USERDETAILSTEQ(
--     ORDERID number(10), 
--     USERNAME varchar2(255), 
--     OTP number(4), 
--     DELIVERY_STATUS varchar2(10),
--     DELIVERY_LOCATION varchar2(255),
--     primary key(ORDERID)
-- );
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;