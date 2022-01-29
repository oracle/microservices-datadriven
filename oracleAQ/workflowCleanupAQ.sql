--Clean up all objects related to the user 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'plsql_UserQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'plsql_UserQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'plsql_UserQueueTable');

--Clean up all objects related to the deliverer 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'plsql_DelivererQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'plsql_DelivererQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'plsql_DelivererQueueTable'); 

--Cleans up all objects related to the application 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'plsql_ApplicationQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'plsql_ApplicationQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'pplsql_ApplicationQueueTable'); 
 

--Clean up all Java Basic Queue Tables and Queues
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_userQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_userQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'java_userQueueTable');

EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_deliQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_deliQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'java_deliQueueTable');

EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'java_appQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'java_appQueueName');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'java_appQueueTable');

--Clean up object type */
DROP TYPE message_typ;
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;