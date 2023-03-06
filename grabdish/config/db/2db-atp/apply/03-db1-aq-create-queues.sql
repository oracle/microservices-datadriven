-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $AQ_USER/"$AQ_PASSWORD"@$DB1_ALIAS

@$COMMON_SCRIPT_HOME/aq-${QUEUE_TYPE}-create-queues.sql

BEGIN
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
END;
/

BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$DB2_CWALLET_SSO_AUTH_URL',
    directory_name => '$DBLINK_CREDENTIAL_DIRECTORY',
    file_name => 'cwallet.sso');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$AQ_USER',
    password => '$AQ_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$DB1_TO_DB2_LINK',
    hostname => '$DB2_HOSTNAME',
    port => '$DB2_PORT',
    service_name => '$DB2_SERVICE_NAME',
    credential_name => 'CRED',
    directory_name => '$DBLINK_CREDENTIAL_DIRECTORY');
END;
/
