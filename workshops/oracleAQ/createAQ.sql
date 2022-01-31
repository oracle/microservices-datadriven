CREATE type obj_typ as object (subject     VARCHAR2(30), text        VARCHAR2(80));  
/
-- Creating an OBJECT type Queue Table and Queue 
BEGIN    
 DBMS_AQADM.CREATE_QUEUE_TABLE (queue_table     => 'objType_classicQueueTable',     queue_payload_type => 'obj_typ');
 DBMS_AQADM.CREATE_QUEUE (queue_name            => 'objType_classicQueue',          queue_table        => 'objType_classicQueueTable');
 DBMS_AQADM.START_QUEUE (queue_name             => 'objType_classicQueue');
END; 
/
-- Creating a RAW type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'rawType_classicQueueTable',     queue_payload_type  => 'RAW');   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'rawType_classicQueue',          queue_table         => 'rawType_classicQueueTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'rawType_classicQueue'); 
END;
/
--Creating a JSON type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'jsonType_classicQueueTable',     queue_payload_type   => 'JSON');  
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'jsonType_classicQueue',          queue_table          => 'jsonType_classicQueueTable');   
 DBMS_AQADM.START_QUEUE ( queue_name            => 'jsonType_classicQueue');
END;
/
-- Creating a Multiconsumer RAW type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'multiconsumer_rawType_classicQueueTable',      queue_payload_type  => 'RAW',                     multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'multiconsumer_rawType_classicQueue',           queue_table         => 'multiconsumer_rawType_classicQueueTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'multiconsumer_rawType_classicQueue'); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
  subscriber := sys.aq$_agent('basicSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'multiconsumer_rawType_classicQueue',   subscriber => subscriber);
END;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;