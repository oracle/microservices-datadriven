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

TO DO CREATE_DATABASE_LINK