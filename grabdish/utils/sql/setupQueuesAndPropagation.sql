--- orderuser...

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    dbms_aqadm.create_sharded_queue (queue_name => 'ORDERTEQ',
                     multiple_consumers => TRUE,
                     queue_properties => qprops);
END;
/

BEGIN
    dbms_aqadm.add_subscriber(queue_name => 'ORDERUSER.ORDERTEQ',
                                   subscriber =>  sys.aq$_agent('sub', NULL, NULL));
END;
/

exec dbms_aqadm.set_queue_parameter('ORDERUSER.ORDERTEQ', 'SHARD_NUM',1) ;

exec dbms_aqadm.start_queue('ORDERTEQ');

begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERTEQ',
                                  destination_queue => 'ORDERTEQ',
                                  destination       => 'ORDERTOINVENTORYLINK',
                                  latency           => 0 );
end;
/

begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERTEQ',
                                  destination_queue => 'INVENTORYUSER.ORDERTEQ',
                                  destination       => 'ORDERTOINVENTORYLINK',
                                  latency           => 0 );
end;
/

--- inventoryuser...

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    dbms_aqadm.create_sharded_queue (queue_name => 'ORDERTEQ',
                     multiple_consumers => FALSE,
                     queue_properties => qprops);
END;
/
