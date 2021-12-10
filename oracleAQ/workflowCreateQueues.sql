
set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/&1@AQDATABASE_TP ;

CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
/
-- Creating a Multiconsumer object type queue table and queue */
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_userQueueTable',      queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'plsql_userQueue',           queue_table         => 'plsql_userQueueTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'plsql_userQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_deliveryQueueTable',   queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'plsql_deliveryQueue',        queue_table         => 'plsql_deliveryQueueTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'plsql_deliveryQueue'); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'plsql_appQueueTable',        queue_payload_type  => 'Message_typ',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'plsql_appQueue',             queue_table         => 'plsql_appQueueTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'plsql_appQueue'); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
  subscriber := sys.aq$_agent('plsql_userSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_userQueue',subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_deliverySubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_deliveryQueue',subscriber => subscriber);

  subscriber := sys.aq$_agent('plsql_appSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'plsql_appQueue',subscriber => subscriber);
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