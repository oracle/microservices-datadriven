-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $AQ_USER/"$AQ_PASSWORD"@$DB2_ALIAS

BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'$INVENTORY_QUEUE',
   subscriber=>sys.aq\$_agent(null,'$AQ_USER.$INVENTORY_QUEUE@$DB2_TO_DB1_LINK',0),
   queue_to_queue => true);
END;
/

BEGIN
dbms_aqadm.schedule_propagation
      (queue_name        => '$AQ_USER.$INVENTORY_QUEUE'
      ,destination_queue => '$AQ_USER.$INVENTORY_QUEUE'
      ,destination       => '$DB2_TO_DB1_LINK'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/
