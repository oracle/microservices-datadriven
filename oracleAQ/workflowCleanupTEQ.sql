--Clean up all objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'plsql_UserTEQ'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_UserTEQ',force=> TRUE);

--Cleans up all objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'plsql_DelivererTEQ');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_DelivererTEQ',force=> TRUE);

--Cleans up all objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'plsql_ApplicationTEQ');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_ApplicationTEQ',force=> TRUE);

--Clean up object type */
DROP TYPE Message_typeTEQ;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;