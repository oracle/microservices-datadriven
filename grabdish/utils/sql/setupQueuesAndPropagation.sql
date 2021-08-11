connect orderuser/orderuserPW@orderpdb_tp

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    dbms_aqadm.create_sharded_queue (queue_name => 'ORDERQUEUE',
                     multiple_consumers => TRUE,
                     queue_properties => qprops);
END;
/

connect inventoryuser/inventoryuserPW@inventorypdb_tp

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    dbms_aqadm.create_sharded_queue (queue_name => 'ORDERQUEUE',
                     multiple_consumers => FALSE,
                     queue_properties => qprops);
END;
/

connect orderuser/orderuserPW@orderpdb_tp

BEGIN
    dbms_aqadm.add_subscriber(queue_name => 'ORDERUSER.ORDERQUEUE',
                                   subscriber =>  sys.aq$_agent('sub', NULL, NULL));
END;
/

exec dbms_aqadm.set_queue_parameter('ORDERUSER.ORDERQUEUE', 'SHARD_NUM',1) ;

exec dbms_aqadm.start_queue('ORDERQUEUE');

connect inventoryuser/inventoryuserPW@inventorypdb_tp

exec dbms_aqadm.start_queue('ORDERQUEUE');

connect orderuser/orderuserPW@orderpdb_tp

begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERQUEUE',
                                  destination_queue => 'INVENTORYUSER.ORDERQUEUE',
                                  destination       => 'ORDERTOINVENTORYLINK',
                                  latency           => 0 );
end;
/

--- inventoryuser...

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    dbms_aqadm.create_sharded_queue (queue_name => 'ORDERQUEUE',
                     multiple_consumers => FALSE,
                     queue_properties => qprops);
END;
/

exec dbms_aqadm.start_queue('ORDERQUEUE');





--- original...


SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

connect sys/knl_test7 as sysdba
drop user propuser cascade;
create user propuser identified by propuser;
grant execute on dbms_aqadm to propuser;
grant execute on dbms_aq to propuser;
grant connect,  resource , unlimited tablespace to propuser;
grant execute on dbms_aqjms to aq;
grant execute on dbms_aqin to aq;
ALTER USER propuser QUOTA 100M ON SYSTEM;

connect propuser/propuser
set echo on
set serveroutput on size unlimited

declare
  qprops       sys.dbms_aqadm.QUEUE_PROPS_T;
BEGIN
    sys.dbms_aqadm.create_sharded_queue (queue_name => 'ORDERSQ',
--                     queue_payload_type => 'RAW',
                     multiple_consumers => TRUE,
                     queue_properties => qprops);
    sys.dbms_aqadm.create_sharded_queue (queue_name => 'INVENTORYQ',
--                     queue_payload_type => 'RAW',
                     multiple_consumers => TRUE,
                     queue_properties => qprops);
    dbms_aqadm.add_subscriber(queue_name => 'PROPUSER.ORDERSQ',
                                   subscriber =>  sys.aq$_agent('sub', NULL, NULL));
    dbms_aqadm.add_subscriber(queue_name => 'PROPUSER.INVENTORYQ',
                                   subscriber =>  sys.aq$_agent('sub1', NULL, NULL));
END;
/

-- Set the total number of shards to 1, this should be executed before
-- executing the start_queue
exec sys.dbms_aqadm.set_queue_parameter('PROPUSER.ORDERSQ', 'SHARD_NUM',1) ;

exec dbms_aqadm.start_queue('ORDERSQ');
exec dbms_aqadm.start_queue('INVENTORYQ');

begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERSQ',
                                  destination_queue => 'INVENTORYQ');

  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERSQ',
                                     destination_queue => 'INVENTORYQ',
                                     destination       => 'pdba',
                                     latency           => 0 );

end;
/







exec dbms_lock.sleep(10);

-- Enqueue some messages into the source queue
declare
  enqueue_options    dbms_aq.enqueue_options_t;
  message_properties dbms_aq.message_properties_t;
  message            BLOB;
  queue_name         VARCHAR2(40);
  message_handle     RAW(16);
BEGIN
   message := to_blob(rawtohex(rpad('a', 1000, 'b'))) ;
   message_properties.priority := 1;
   message_properties.correlation := 'correlation-id';
   for i in 1..10 loop
     dbms_aq.enqueue(queue_name => 'ORDERSQ',
                     enqueue_options    => enqueue_options,
                     message_properties => message_properties,
                     payload            => message,
                     msgid              => message_handle);
   end loop ;
   COMMIT;
END;
/

set pagesize 100
select msgid from INVENTORYQ order by seq_num;

--begin
--  dbms_aqadm.unschedule_propagation(queue_name        => 'ORDERSQ',
--                                    destination_queue => 'INVENTORYQ');
--end ;
--/

SET ECHO OFF
SET SERVEROUTPUT OFF




--DROP QUEUE
BEGIN
  DBMS_AQADM.STOP_QUEUE(queue_name => 'ORDERQUEUE');
  DBMS_AQADM.DROP_QUEUE(queue_name => 'ORDERQUEUE');
  DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ORDERQUEUETABLE');
END;



