--Clean up all objects related to the obj type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       => 'aq_obj');  
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       => 'aq_obj');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      => 'aq_obj_queueTable');

--Clean up all objects related to the RAW type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       =>'aq_raw');   
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       =>'aq_raw');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      =>'aq_raw_queueTable'); 

--Clean up all objects related to the JSON type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       =>'aq_JSON');   
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       =>'aq_JSON');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      =>'aq_JSON_queueTable'); 

--Cleans up all objects related to the RAW type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       =>'aq_multiconsumer_raw');   
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       =>'aq_multiconsumer_raw');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      =>'aq_multiconsumer_raw_queueTable'); 
 

--Clean up all Java Basic Queue Tables and Queues
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_QueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_QueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'JAVA_QUEUETABLE');

EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_QueueName_Multi');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_QueueName_Multi');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'java_QueueTable_Multi');

EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_basicOracleQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_basicOracleQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'java_basicOracleQueue_queueTable');

--Clean up object type 
DROP TYPE obj_typ;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;
