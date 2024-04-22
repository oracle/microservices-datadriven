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
/
select name, queue_table,queue_category, recipients from all_queues where OWNER='JAVAUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;
