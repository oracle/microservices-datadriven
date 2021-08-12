Set
ECHO ON

SET ECHO ON;

EXECUTE SYS.DBMS_AQADM.CREATE_QUEUE_TABLE(queue_table = > 'ORDERQUEUETABLE',
                                          queue_payload_type = > 'SYS.AQ$_JMS_TEXT_MESSAGE', compatible = > '8.1');

EXECUTE DBMS_AQADM.CREATE_QUEUE(queue_name = > 'ORDERQUEUE', queue_table = > 'ORDERQUEUETABLE');

EXECUTE DBMS_AQADM.START_QUEUE(queue_name = > 'ORDERQUEUE');


EXECUTE DBMS_AQADM.CREATE_QUEUE_TABLE(queue_table = > 'ORDERQUEUETABLE',
                                      queue_payload_type = > 'SYS.AQ$_JMS_TEXT_MESSAGE', compatible = > '8.1');



BEGIN
    DBMS_AQADM.CREATE_QUEUE_TABLE
(
            queue_table          => 'ORDERUSER."ORDERQUEUETABLE"',
            queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
            multiple_consumers   => true,
            compatible           => '8.1');

    DBMS_AQADM.CREATE_QUEUE
(
            queue_name          => '"ORDERQUEUE"',
            queue_table         => '"ORDERQUEUETABLE"');

    DBMS_AQADM.START_QUEUE
(
            queue_name          => '"ORDERQUEUE"');
END;
/

BEGIN
    DBMS_AQADM.CREATE_QUEUE_TABLE
(
            queue_table          => 'ORDERUSER."INVENTORYQUEUETABLE"',
            queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
            compatible           => '8.1');

    DBMS_AQADM.CREATE_QUEUE
(
            queue_name          => 'INVENTORYQUEUE',
            queue_table         => 'INVENTORYQUEUETABLE');

    DBMS_AQADM.START_QUEUE
(
            queue_name          => 'INVENTORYQUEUE');
END;
/

quit
