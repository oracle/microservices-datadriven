CREATE TABLE USERDETAILS(
    ORDERID number(10), 
    USERNAME varchar2(255), 
    OTP number(4), 
    DELIVERYSTATUS varchar2(10),
    DELIVERYLOCATION varchar2(255),
    primary key(ORDERID)
);
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'JAVA_TEQ_USER_QUEUE',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'java_user for TEQ', 
     queue_payload_type =>'JMS', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_USER_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'JAVA_TEQ_DELIVERER_QUEUE',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'java_deliverer for TEQ', 
     queue_payload_type =>'JMS', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_DELIVERER_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'JAVA_TEQ_APPLICATION_QUEUE',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'java_appQueue for TEQ', 
     queue_payload_type=>'JMS', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_APPLICATION_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'JAVA_TEQ_PUBSUB_QUEUE',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'java_appQueue for TEQ', 
     queue_payload_type=>'JMS', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'JAVA_TEQ_PUBSUB_QUEUE', enqueue =>TRUE, dequeue=> True); 
END;
/
