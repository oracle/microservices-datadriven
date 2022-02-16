--PLSQL: Clean up objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'teq_UserQueue'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'teq_UserQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'teq_DelivererQueue');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'teq_DelivererQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'teq_ApplicationQueue');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'teq_ApplicationQueue',force=> TRUE);

--Clean up object type */
DROP TYPE Message_typ;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;