--PLSQL: Clean up objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'TxEventQ_UserQueue'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'TxEventQ_UserQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'TxEventQ_DelivererQueue');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'TxEventQ_DelivererQueue',force=> TRUE);

--PLSQL: Cleans up objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'TxEventQ_ApplicationQueue');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'TxEventQ_ApplicationQueue',force=> TRUE);

--Clean up object type */
DROP TYPE Message_typ;
/
select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='DBUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;