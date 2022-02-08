
CREATE type obj_typ as object (subject     VARCHAR2(30), text        VARCHAR2(80));  
/
-- Creating an OBJECT type Queue Table and Queue 
BEGIN    
 DBMS_AQADM.CREATE_QUEUE_TABLE (queue_table     => 'objType_AQTable',     queue_payload_type => 'obj_typ');
 DBMS_AQADM.CREATE_QUEUE (queue_name            => 'objType_AQ',          queue_table        => 'objType_AQTable');
 DBMS_AQADM.START_QUEUE (queue_name             => 'objType_AQ');
END; 
/
-- Creating a RAW type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'rawType_AQTable',     queue_payload_type  => 'RAW');   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'rawType_AQ',          queue_table         => 'rawType_AQTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'rawType_AQ'); 
END;
/
--Creating a JSON type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'jsonType_AQTable',     queue_payload_type   => 'JSON');  
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'jsonType_AQ',          queue_table          => 'jsonType_AQTable');   
 DBMS_AQADM.START_QUEUE ( queue_name            => 'jsonType_AQ');
END;
/
-- Creating a Multiconsumer RAW type queue table and queue 
BEGIN
 DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'multiconsumer_rawType_AQTable',  queue_payload_type  => 'RAW',    multiple_consumers => TRUE);   
 DBMS_AQADM.CREATE_QUEUE ( queue_name           => 'multiconsumer_rawType_AQ',       queue_table         => 'multiconsumer_rawType_AQTable');  
 DBMS_AQADM.START_QUEUE ( queue_name            => 'multiconsumer_rawType_AQ'); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
  subscriber := sys.aq$_agent('basicSubscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'multiconsumer_rawType_AQ',   subscriber => subscriber);
END;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;