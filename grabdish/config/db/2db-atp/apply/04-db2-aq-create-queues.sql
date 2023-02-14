-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $AQ_USER/"$AQ_PASSWORD"@$DB2_ALIAS

@$COMMON_SCRIPT_HOME/aq-${QUEUE_TYPE}-create-queues.sql

BEGIN
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

   DBMS_AQADM.add_subscriber(
      queue_name=>'$ORDER_QUEUE',
      subscriber=>sys.aq\$_agent('inventory_service',NULL,NULL));
END;
/

BEGIN

  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$DB1_CWALLET_SSO_AUTH_URL',
    directory_name => '$DBLINK_CREDENTIAL_DIRECTORY',
    file_name => 'cwallet.sso');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$AQ_USER',
    password => '$AQ_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$DB2_TO_DB1_LINK',
    hostname => '$DB1_HOSTNAME',
    port => '$DB1_PORT',
    service_name => '$DB1_SERVICE_NAME',
    credential_name => 'CRED',
    directory_name => '$DBLINK_CREDENTIAL_DIRECTORY');
END;
/
