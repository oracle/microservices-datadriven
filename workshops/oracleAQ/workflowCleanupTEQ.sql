--PLSQL: Clean up objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'plsql_UserQueue'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_UserQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'plsql_DelivererQueue');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_DelivererQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'plsql_ApplicationQueue');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_ApplicationQueue',force=> TRUE);

--PLSQL: Clean up objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'java_UserQueue'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_UserQueue',force=> TRUE);

--JAVA: Cleans up objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'java_DelivererQueue');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_DelivererQueue',force=> TRUE);

--JAVA: Cleans up objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'java_ApplicationQueue');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_ApplicationQueue',force=> TRUE);


--Clean up object type */
DROP TYPE Message_typeTEQ;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;