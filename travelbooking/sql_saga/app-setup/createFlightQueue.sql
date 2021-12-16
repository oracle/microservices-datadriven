SET ECHO ON;

EXECUTE SYS.DBMS_AQADM.CREATE_QUEUE_TABLE(queue_table = > 'FLIGHTQUEUETABLE',
                                          queue_payload_type = > 'SYS.AQ$_JMS_TEXT_MESSAGE', compatible = > '8.1');

BEGIN
   DBMS_AQADM.CREATE_QUEUE_TABLE (
      queue_table          => 'FLIGHTQUEUETABLE',
      queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true,
      compatible           => '8.1');

   DBMS_AQADM.CREATE_QUEUE (
      queue_name          => 'FLIGHTQUEUE',
      queue_table         => 'FLIGHTQUEUETABLE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => 'FLIGHTQUEUE');

END;
/
