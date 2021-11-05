BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'ORDERQUEUE',
queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
multiple_consumers   => true,
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => 'ORDERQUEUE',
queue_table         => 'ORDERQUEUE');

DBMS_AQADM.START_QUEUE (
queue_name          => 'ORDERQUEUE');
END;
/

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'INVENTORYQUEUE',
queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
multiple_consumers   => false,
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => 'INVENTORYQUEUE',
queue_table         => 'INVENTORYQUEUE');

DBMS_AQADM.START_QUEUE (
queue_name          => 'INVENTORYQUEUE');
END;
/