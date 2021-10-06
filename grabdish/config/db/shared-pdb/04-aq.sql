connect $AQ_USER/"$AQ_PASSWORD"@$DB_SVC

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => '${ORDER_QUEUE}TABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
multiple_consumers   => true,
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$ORDER_QUEUE',
queue_table         => '${ORDER_QUEUE}TABLE');

DBMS_AQADM.grant_queue_privilege (
   privilege     =>     'ENQUEUE',
   queue_name    =>     '$ORDERQUEUE',
   grantee       =>     '$ORDER_USER',
   grant_option  =>      FALSE);

DBMS_AQADM.grant_queue_privilege (
   privilege     =>     'DEQUEUE',
   queue_name    =>     '$ORDERQUEUE',
   grantee       =>     '$INVENTORY_USER',
   grant_option  =>      FALSE);

DBMS_AQADM.START_QUEUE (
queue_name          => '$ORDER_QUEUE');
END;
/

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => '${INVENTORY_QUEUE}TABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$INVENTORY_QUEUE',
queue_table         => '${INVENTORY_QUEUE}TABLE');

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

DBMS_AQADM.START_QUEUE (
queue_name          => '$INVENTORY_QUEUE');
END;
/