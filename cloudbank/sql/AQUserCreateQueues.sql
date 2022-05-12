-- Copyright (c) 2022 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

BEGIN
   DBMS_AQADM.CREATE_QUEUE_TABLE (
      queue_table          => 'BANKAQUEUETABLE',
      queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true,
      compatible           => '8.1');

   DBMS_AQADM.CREATE_QUEUE_TABLE (
      queue_table          => 'BANKBQUEUETABLE',
      queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
      multiple_consumers   => true,
      compatible           => '8.1');

   DBMS_AQADM.CREATE_QUEUE (
      queue_name          => 'BANKAQUEUE',
      queue_table         => 'BANKAQUEUETABLE');

   DBMS_AQADM.CREATE_QUEUE (
      queue_name          => 'BANKBQUEUE',
      queue_table         => 'BANKBQUEUETABLE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => 'BANKAQUEUE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => 'BANKBQUEUE');

--       2hr retention - todo, remove or set as appropriate/common
   DBMS_AQADM.ALTER_QUEUE(
      queue_name        => 'BANKAQUEUE',
      retention_time    => 3600);

END;
/

BEGIN
   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'ENQUEUE',
      queue_name    =>     'BANKAQUEUE',
      grantee       =>     'BANKAUSER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'DEQUEUE',
      queue_name    =>     'BANKAQUEUE',
      grantee       =>     'BANKBUSER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'ENQUEUE',
      queue_name    =>     'BANKBQUEUE',
      grantee       =>     'BANKBUSER',
      grant_option  =>      FALSE);

   DBMS_AQADM.grant_queue_privilege (
      privilege     =>     'DEQUEUE',
      queue_name    =>     'BANKBQUEUE',
      grantee       =>     'BANKAUSER',
      grant_option  =>      FALSE);

   DBMS_AQADM.add_subscriber(
      queue_name=>'BANKAQUEUE',
      subscriber=>sys.aq$_agent('bankb_service',NULL,NULL));

   DBMS_AQADM.add_subscriber(
      queue_name=>'BANKBQUEUE',
      subscriber=>sys.aq$_agent('banka_service',NULL,NULL));
END;
/
