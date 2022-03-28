--Clean up all objects related to the obj type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       => 'PYTHON_ADT_Q');  
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       => 'PYTHON_ADT_Q');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      => 'PYTHON_ADT_QTable');

--Clean up all objects related to the RAW type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       =>'PYTHON_RAW_Q');   
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       =>'PYTHON_RAW_Q');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      =>'PYTHON_RAW_QTable'); 

--Clean up all objects related to the JSON type: 
EXECUTE DBMS_AQADM.STOP_QUEUE       ( queue_name       =>'PYTHON_JMS_Q');   
EXECUTE DBMS_AQADM.DROP_QUEUE       ( queue_name       =>'PYTHON_JMS_Q');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table      =>'PYTHON_JMS_QTable'); 

select name, queue_table,queue_category, recipients from all_queues where OWNER='JAVAUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;