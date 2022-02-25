
CREATE type obj_typ as object (subject     VARCHAR2(30), text        VARCHAR2(80));  
/
-- Creating an OBJECT type Queue Table and Queue     
 EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_obj_queueTable',     queue_payload_type => 'obj_typ');
 EXECUTE DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_obj',                queue_table        => 'aq_obj_queueTable');
 EXECUTE DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_obj');

-- Creating a RAW type queue table and queue 
 EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_raw_queueTable',     queue_payload_type  => 'RAW');   
 EXECUTE DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_raw',                queue_table         => 'aq_raw_queueTable');  
 EXECUTE DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_raw'); 

--Creating a JSON type queue table and queue 
 EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_json_queueTable',     queue_payload_type   => 'JSON');  
 EXECUTE DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_json',                queue_table          => 'aq_json_queueTable');   
 EXECUTE DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_json');

-- Creating a Multiconsumer RAW type queue table and queue 
 EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'aq_multiconsumer_raw_queueTable',  queue_payload_type  => 'RAW',    multiple_consumers => TRUE);   
 EXECUTE DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'aq_multiconsumer_raw',             queue_table         => 'aq_multiconsumer_raw_queueTable');  
 EXECUTE DBMS_AQADM.START_QUEUE        ( queue_name     => 'aq_multiconsumer_raw'); 

DECLARE
  subscriber sys.aq$_agent;
BEGIN
  subscriber := sys.aq$_agent('aq_Subscriber', NULL, NULL);
  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'aq_multiconsumer_raw',   subscriber => subscriber);
END;
/
EXIT;