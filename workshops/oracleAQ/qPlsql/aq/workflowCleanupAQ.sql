--Clean up all objects related to the user 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'aq_UserQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'aq_UserQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'aq_UserQueueTable');

--Clean up all objects related to the deliverer 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'aq_DelivererQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'aq_DelivererQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'aq_DelivererQueueTable'); 

--Cleans up all objects related to the application 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'aq_ApplicationQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'aq_ApplicationQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'aq_ApplicationQueueTable'); 

--JAVA:
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'JAVA_AQ_USER_QUEUE');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'JAVA_AQ_USER_QUEUE');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'JAVA_AQ_USER_QUEUE_TABLE');

--Clean up all objects related to the deliverer 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'JAVA_AQ_DELIVERER_QUEUE');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'JAVA_AQ_DELIVERER_QUEUE');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'JAVA_AQ_DELIVERER_QUEUE_TABLE'); 

--Cleans up all objects related to the application 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'JAVA_AQ_APPLICATION_QUEUE');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'JAVA_AQ_APPLICATION_QUEUE');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'JAVA_AQ_APPLICATION_QUEUE_TABLE'); 

--Clean up object type */
DROP TYPE message_typ;
select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='DBUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;