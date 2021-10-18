-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $AQ_USER/"$AQ_PASSWORD"@$DB1_ALIAS

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
      queue_name    =>     '$INVENTORY_QUEUE',
      grantee       =>     '$ORDER_USER',
      grant_option  =>      FALSE);

   DBMS_AQADM.add_subscriber(
      queue_name=>'$INVENTORY_QUEUE',
      subscriber=>sys.aq\$_agent('order_service',NULL,NULL));

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$ORDER_QUEUE');

   DBMS_AQADM.START_QUEUE (
      queue_name          => '$INVENTORY_QUEUE');

END;
/

CREATE OR REPLACE DIRECTORY dblink_wallet_dir AS 'dblink_wallet_dir';

BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$DB2_CWALLET_SSO_AUTH_URL',
    directory_name => 'dblink_wallet_dir');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$AQ_USER',
    password => '$AQ_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$DB1_TO_DB2_LINK',
    hostname => '$DB2_HOSTNAME',
    port => '$DB2_PORT',
    service_name => '$DB2_SERVICE_NAME',
    ssl_server_cert_dn => '$DB2_SSL_SERVER_CERT_DN',
    credential_name => 'CRED',
    directory_name => 'dblink_wallet_dir');
END;
/
