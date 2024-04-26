begin
dbms_aqadm.create_transactional_event_queue (queue_name => 'TollGate', multiple_consumers => true);
dbms_aqadm.set_queue_parameter('TollGate', 'KEY_BASED_ENQUEUE', 2);
dbms_aqadm.set_queue_parameter('TollGate', 'SHARD_NUM', 5);
dbms_aqadm.start_queue('TollGate');
end;


begin
  dbms_aqadm.create_transactional_event_queue (queue_name => 'TollGate', multiple_consumers => false);
  --dbms_aqadm.set_queue_parameter('TollGate', 'KEY_BASED_ENQUEUE', 2);
  --dbms_aqadm.set_queue_parameter('TollGate', 'SHARD_NUM', 5);
  dbms_aqadm.start_queue('TollGate') ;
end;

select msg_id, utl_raw.cast_to_varchar2(dbms_lob.substr(user_data)), msg_state from aq$tollgate;
 
begin
   dbms_aqadm.stop_queue('TollGate');
   dbms_aqadm.drop_queue('TollGate');
 end;
