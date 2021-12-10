  set cloudconfig ./oracleAQ/network/admin/wallet.zip
connect DBUSER/&1@AQDATABASE_TP ;
/
--Clean up all objects related to the obj type: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'objType_TEQ'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'objType_TEQ',force=> TRUE);

--Cleans up all objects related to the RAW type: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'rawType_TEQ');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'rawType_TEQ',force=> TRUE);

--Cleans up all objects related to the priority queue: */
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'jsonType_TEQ');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'jsonType_TEQ',force=> TRUE);

--Clean up object type */
DROP TYPE Message_type;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;