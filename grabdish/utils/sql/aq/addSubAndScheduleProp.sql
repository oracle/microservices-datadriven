
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
ORDERTOINVENTORYLINK=INVENTORYPDB

BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'ADMIN.ORDERQUEUE',
   subscriber=>sys.aq$_agent(null,'ADMIN.ORDERQUEUE@INVENTORYPDB',0),
   queue_to_queue => true);
END;
/
BEGIN
dbms_aqadm.schedule_propagation
      (queue_name        => 'ADMIN.ORDERQUEUE'
      ,destination_queue => 'ADMIN.ORDERQUEUE'
      ,destination       => 'INVENTORYPDB'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/
EXECUTE DBMS_AQADM.ENABLE_PROPAGATION_SCHEDULE ( 'ADMIN.ORDERQUEUE', 'INVENTORYPDB', 'ADMIN.ORDERQUEUE');
EXECUTE DBMS_AQADM.DISABLE_PROPAGATION_SCHEDULE ( 'admin.orderqueue', 'INVENTORYPDB', 'admin.orderqueue@INVENTORYPDB');
BEGIN
DBMS_AQADM.remove_subscriber(
   queue_name=>'ADMIN.ORDERQUEUE',
   subscriber=>sys.aq$_agent(null,'ADMIN.ORDERQUEUE@INVENTORYPDB',0));
END;
/
BEGIN
dbms_aqadm.unschedule_propagation
      (queue_name        => 'ADMIN.ORDERQUEUE'
      ,destination_queue => 'ADMIN.ORDERQUEUE@INVENTORYPDB'
      ,destination       => 'INVENTORYPDB');     --No gap before propagating
END;
/


-- older...


BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'ORDERQUEUE',
   subscriber=>sys.aq\$_agent(null,'INVENTORYUSER.ORDERQUEUE@INVENTORYPDB',0),
   queue_to_queue => true);
END;
/

BEGIN
dbms_aqadm.schedule_propagation
      (queue_name        => 'ORDERUSER.ORDERQUEUE'
      ,destination_queue => 'INVENTORYUSER.ORDERQUEUE'
      ,destination       => 'INVENTORYPDB'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/


--ORIGINAL

BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'$Q',
   subscriber=>sys.aq\$_agent(null,'$TU.$Q@$LINK',0),
   queue_to_queue => true);
END;
/

BEGIN
dbms_aqadm.schedule_propagation
      (queue_name        => '$U.$Q'
      ,destination_queue => '$TU.$Q'
      ,destination       => '$LINK'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/