CREATE TYPE Message_typ AS OBJECT (ORDERID NUMBER(10), USERNAME VARCHAR2(255), OTP NUMBER(4), DELIVERY_STATUS VARCHAR2(10),DELIVERY_LOCATION VARCHAR2(255)); 
/
-- Creating an Object type queue 
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'teq_UserQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'teq_user', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_UserQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name         =>'teq_DelivererQueue',
     storage_clause     =>null, 
     multiple_consumers =>true, 
     max_retries        =>10,
     comment            =>'teq_deliverer', 
     queue_payload_type =>'Message_typ', 
     queue_properties   =>null, 
     replication_mode   =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_DelivererQueue', enqueue =>TRUE, dequeue=> True); 
END;
/
BEGIN
 DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
     queue_name        =>'teq_ApplicationQueue',
     storage_clause    =>null, 
     multiple_consumers=>true, 
     max_retries       =>10,
     comment           =>'teq_appQueue', 
     queue_payload_type=>'Message_typ', 
     queue_properties  =>null, 
     replication_mode  =>null);
 DBMS_AQADM.START_QUEUE (queue_name=> 'teq_ApplicationQueue', enqueue =>TRUE, dequeue=> True); 
END;
/

DECLARE
  subscriber sys.aq$_agent;
BEGIN

--PLSQL: USER Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_UserQueue'       , subscriber => sys.aq$_agent('teq_userAppSubscriber'      , null ,0), rule => 'correlation = ''teq_userAppSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_UserQueue'       , subscriber => sys.aq$_agent('teq_userDelivererSubscriber', null ,0), rule => 'correlation = ''teq_userDelivererSubscriber''');

--PLSQL: Deliverer Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_DelivererQueue'  , subscriber => sys.aq$_agent('teq_delivererUserSubscriber', null ,0), rule => 'correlation = ''teq_delivererUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_DelivererQueue'  , subscriber => sys.aq$_agent('teq_delivererAppSubscriber' , null ,0), rule => 'correlation = ''teq_delivererAppSubscriber''');

--PLSQL: Application Subscriber
dbms_aqadm.add_subscriber(queue_name => 'teq_ApplicationQueue', subscriber => sys.aq$_agent('teq_appUserSubscriber'      , null ,0), rule => 'correlation = ''teq_appUserSubscriber''');
dbms_aqadm.add_subscriber(queue_name => 'teq_ApplicationQueue', subscriber => sys.aq$_agent('teq_appDelivererSubscriber' , null ,0), rule => 'correlation = ''teq_appDelivererSubscriber''');

END;
/
select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='DBUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE';
/
EXIT;