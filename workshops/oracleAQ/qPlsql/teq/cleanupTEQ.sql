--Clean up all objects related to the obj type: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'objType_TEQ'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'objType_TEQ',force=> TRUE);

--Cleans up all objects related to the RAW type: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'rawType_TEQ');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'rawType_TEQ',force=> TRUE);

--Cleans up all objects related to the priority queue: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'jsonType_TEQ');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'jsonType_TEQ',force=> TRUE);
/
select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='DBUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;