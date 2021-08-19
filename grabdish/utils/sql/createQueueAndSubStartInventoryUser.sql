declare
    qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    sys.dbms_aqadm.create_sharded_queue (queue_name => 'ORDERQ',
                     multiple_consumers => TRUE,
                     queue_properties => qprops);
END;
/

declare
  sub sys.aq$_agent;
begin
  sub := sys.aq$_agent('oagent1', NULL, null);
  dbms_aqadm.add_subscriber('ORDERQ',sub);
  dbms_output.put_line('Added subscriber to INVENTORYQ');
end;
/

exec dbms_aqadm.start_queue('ORDERQ');
