#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

export TNS_ADMIN=$GRABDISH_HOME/wallet
ORDER_DB_SVC="$(state_get ORDER_DB_NAME)_tp"
INVENTORY_DB_SVC="$(state_get INVENTORY_DB_NAME)_tp"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
ORDER_LINK=ORDERTOINVENTORYLINK
INVENTORY_LINK=INVENTORYTOORDERLINK
ORDER_QUEUE=ORDERQUEUE
INVENTORY_QUEUE=INVENTORYQUEUE
DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`

U=$ORDER_USER
SVC=$ORDER_DB_SVC
TU=$INVENTORY_USER
TSVC=$INVENTORY_DB_SVC
LINK=$ORDER_LINK
Q=$ORDER_QUEUE
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC
BEGIN

DBMS_AQADM.UNSCHEDULE_PROPAGATION  (queue_name        => '$U.$Q'
      ,destination_queue => '$TU.$Q'
      ,destination       => '$LINK');
   
dbms_aqadm.schedule_propagation
      (queue_name        => '$U.$Q'
      ,destination_queue => '$TU.$Q'
      ,destination       => '$LINK'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/
!

U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
TU=$ORDER_USER
TSVC=$ORDER_DB_SVC
LINK=$INVENTORY_LINK
Q=$INVENTORY_QUEUE
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC
BEGIN

DBMS_AQADM.UNSCHEDULE_PROPAGATION  (queue_name        => '$U.$Q'
      ,destination_queue => '$TU.$Q'
      ,destination       => '$LINK');
   
dbms_aqadm.schedule_propagation
      (queue_name        => '$U.$Q'
      ,destination_queue => '$TU.$Q'
      ,destination       => '$LINK'
      ,start_time        => sysdate --immediately
      ,duration          => null    --until stopped
      ,latency           => 0);     --No gap before propagating
END;
/
!

