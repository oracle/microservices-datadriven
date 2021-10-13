WHENEVER SQLERROR EXIT 1
connect $AQ_USER/"$AQ_PASSWORD"@$DB_SVC

BEGIN
   DBMS_AQADM.CREATE_QUEUE_TABLE (
      queue_table          => 'QUEUETABLE',
      queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true,
      compatible           => '8.1');

   DBMS_AQADM.CREATE_QUEUE (
      queue_name          => '$ORDER_QUEUE',
      queue_table         => 'QUEUETABLE');

   DBMS_AQADM.CREATE_QUEUE (
      queue_name          => '$INVENTORY_QUEUE',
      queue_table         => 'QUEUETABLE');

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'ENQUEUE',
      queue_name    =>     '$ORDER_QUEUE',
      grantee       =>     '$ORDER_USER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'DEQUEUE',
      queue_name    =>     '$ORDER_QUEUE',
      grantee       =>     '$INVENTORY_USER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'ENQUEUE',
      queue_name    =>     '$INVENTORY_QUEUE',
      grantee       =>     '$INVENTORY_USER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'DEQUEUE',
      queue_name    =>     '$INVENTORY_QUEUE',
      grantee       =>     '$ORDER_USER',
      grant_option  =>      FALSE);

--   DBMS_AQADM.add_subscriber(
--      queue_name=>'$ORDER_QUEUE',
--      subscriber=>sys.aq\$_agent('inventory_service',NULL,NULL));

--   DBMS_AQADM.add_subscriber(
--      queue_name=>'$INVENTORY_QUEUE',
--      subscriber=>sys.aq\$_agent('order_service',NULL,NULL));

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$ORDER_QUEUE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$INVENTORY_QUEUE');

END;
/
