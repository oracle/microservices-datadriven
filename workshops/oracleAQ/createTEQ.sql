
CREATE type Message_type as object (subject     VARCHAR2(30), text        VARCHAR2(80));  
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'objType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'ObjectType for TEQ', 
     queue_payload_type =>'Message_type', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'objType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/

-- Creating a RAW type queue: 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'rawType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'RAW type for TEQ', 
     queue_payload_type =>'RAW', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'rawType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/

--Creating JSON type queue:
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'jsonType_TEQ',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'jsonType for TEQ', 
     queue_payload_type =>'JSON', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'jsonType_TEQ', enqueue =>TRUE, dequeue=> True); 
END;
/
DECLARE
  subscriber sys.aq$_agent;
BEGIN
dbms_aqadm.add_subscriber(queue_name => 'objType_TEQ'       , subscriber => sys.aq$_agent('teqBasicObjSubscriber'      , null ,0), rule => 'correlation = ''teqBasicObjSubscriber''');

dbms_aqadm.add_subscriber(queue_name => 'rawType_TEQ'       , subscriber => sys.aq$_agent('teqBasicRawSubscriber'      , null ,0), rule => 'correlation = ''teqBasicRawSubscriber''');

dbms_aqadm.add_subscriber(queue_name => 'jsonType_TEQ'       , subscriber => sys.aq$_agent('teqBasicJsonSubscriber'      , null ,0), rule => 'correlation = ''teqBasicJsonSubscriber''');

END;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;      