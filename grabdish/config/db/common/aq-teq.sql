-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


BEGIN
   DBMS_AQADM.CREATE_SHARDED_QUEUE (
      queue_name          => '$ORDER_QUEUE',
      queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true);

   DBMS_AQADM.CREATE_SHARDED_QUEUE (
      queue_name          => '$INVENTORY_QUEUE',
      queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true);

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$ORDER_QUEUE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$INVENTORY_QUEUE');

END;
/
