#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

export TNS_ADMIN=$TRAVELBOOKING_HOME/wallet
TRAVELAGENCYDB_SVC="$(state_get TRAVELAGENCYDB_NAME)_tp"
PARTICIPANTDB_SVC="$(state_get PARTICIPANTDB_NAME)_tp"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
ORDER_LINK=ORDERTOINVENTORYLINK
INVENTORY_LINK=INVENTORYTOORDERLINK
ORDER_QUEUE=ORDERQUEUE
INVENTORY_QUEUE=INVENTORYQUEUE
DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`

U=$ORDER_USER
SVC=$TRAVELAGENCYDB_SVC
TU=$INVENTORY_USER
TSVC=$PARTICIPANTDB_SVC
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
SVC=$PARTICIPANTDB_SVC
TU=$ORDER_USER
TSVC=$TRAVELAGENCYDB_SVC
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

