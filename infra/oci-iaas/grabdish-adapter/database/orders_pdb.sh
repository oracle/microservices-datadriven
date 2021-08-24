#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


#added for on-premise

#state_set_done OBJECT_STORE_BUCKET
#state_set_done ORDER_DB_OCID
#state_set_done INVENTORY_DB_OCID
#state_set_done WALLET_GET
#state_set_done CWALLET_SSO_OBJECT
#state_set_done DB_PASSWORD


state_set ORDER_DB_NAME orders
state_set INVENTORY_DB_NAME inventory


# DB Connection Setup
ORDER_DB_SVC="$(state_get ORDER_DB_NAME)"
INVENTORY_DB_SVC="$(state_get INVENTORY_DB_NAME)"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
ORDER_LINK=ORDERTOINVENTORYLINK
INVENTORY_LINK=INVENTORYTOORDERLINK
ORDER_QUEUE=ORDERQUEUE
INVENTORY_QUEUE=INVENTORYQUEUE


# Get DB Password
while true; do
  if DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`; then
    if ! test -z "$DB_PASSWORD"; then
      break
    fi
  fi
  echo "Error: Failed to get DB password.  Retrying..."
  sleep 5
done



# Create Orders PDB
U=$ORDER_USER
SVC=${ORDER_DB_SVC}
echo "##########   Creating Orders PDB ###########"
sqlplus /nolog <<!
/* WHENEVER SQLERROR EXIT
*/
connect / as sysdba
alter pluggable database ${SVC} close immediate instances=all;
drop pluggable database ${SVC}  including datafiles;
CREATE PLUGGABLE DATABASE ${SVC}
ADMIN USER admin IDENTIFIED BY "${DB_PASSWORD}"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '/u01/app/oracle/oradat/ORCL/${SVC}/$SVC01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '/u01/app/oracle/oradat/ORCL/dbs/${SVC}/'
FILE_NAME_CONVERT = ('/u01/app/oracle/oradat/ORCL/pdbseed/', '/u01/app/oracle/oradat/ORCL/${SVC}/');
alter pluggable database ${SVC}  open;
!


exit

# Create Inventory PDB
U=$INVENTORY_USER
SVC=${INVENTORY_DB_SVC}
echo "##########   Creating Inventory PDB ###########"
sqlplus /nolog <<!
/*
WHENEVER SQLERROR EXIT
*/
connect / as sysdba
alter pluggable database ${SVC} close immediate instances=all;
drop pluggable database ${SVC}  including datafiles;
CREATE PLUGGABLE DATABASE ${SVC}
ADMIN USER admin IDENTIFIED BY "${DB_PASSWORD}"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '/u01/app/oracle/oradata/ORCL/${SVC}/$SVC01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '/u01/app/oracle/oradata/ORCL/dbs/${SVC}/'
FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/pdbseed/', '/u01/app/oracle/oradata/ORCL/${SVC}/');

alter pluggable database ${SVC}  open;
!

#update Oracle listeners file

echo "##########  Reloading Database Listeners  ###########"
lsnrctl reload


echo "##########   Granting Access to Order User, Creating Order PDB Queues  ###########"
# Order DB User, Objects
while ! state_done ORDER_USER; do
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
#connect admin/"$DB_PASSWORD"@$SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect / as sysdba;
alter session set container=$SVC;
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD";
GRANT pdb_dba TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;

GRANT SODA_APP to $U;


connect $U/"$DB_PASSWORD"@${SVC}_tp

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'ORDERQUEUETABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
multiple_consumers   => true,
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$ORDER_QUEUE',
queue_table         => 'ORDERQUEUETABLE');

DBMS_AQADM.START_QUEUE (
queue_name          => '$ORDER_QUEUE');
END;
/

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'INVENTORYQUEUETABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$INVENTORY_QUEUE',
queue_table         => 'INVENTORYQUEUETABLE');

DBMS_AQADM.START_QUEUE (
queue_name          => '$INVENTORY_QUEUE');
END;
/
!
  state_set_done ORDER_USER
done

echo "##########   Granting Access to Inventory User, Creating Inventory PDB Queues  ###########"
echo $U/"$DB_PASSWORD"@${SVC}_tp
echo "#############DEBUGGING"


# Inventory DB User, Objects
while ! state_done INVENTORY_USER; do
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
echo "##########   Granting Access to Inventory User, Creating Inventory PDB Queues  ###########"
echo $U/"$DB_PASSWORD"@${SVC}_tp
echo "#############DEBUGGING"  
  #connect admin/"$DB_PASSWORD"@$SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect / as sysdba;
alter session set container=$SVC;
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD";
GRANT pdb_dba TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;

connect $U/"$DB_PASSWORD"@${SVC}_tp

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'ORDERQUEUETABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$ORDER_QUEUE',
queue_table         => 'ORDERQUEUETABLE');

DBMS_AQADM.START_QUEUE (
queue_name          => '$ORDER_QUEUE');
END;
/

BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
queue_table          => 'INVENTORYQUEUETABLE',
queue_payload_type   => 'SYS.AQ\$_JMS_TEXT_MESSAGE',
multiple_consumers   => true,
compatible           => '8.1');

DBMS_AQADM.CREATE_QUEUE (
queue_name          => '$INVENTORY_QUEUE',
queue_table         => 'INVENTORYQUEUETABLE');

DBMS_AQADM.START_QUEUE (
queue_name          => '$INVENTORY_QUEUE');
END;
/

create table inventory (
  inventoryid varchar(16) PRIMARY KEY NOT NULL,
  inventorylocation varchar(32),
  inventorycount integer CONSTRAINT positive_inventory CHECK (inventorycount >= 0) );

insert into inventory values ('sushi', '1468 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('pizza', '1469 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('burger', '1470 WEBSTER ST,San Francisco,CA', 0);
commit;
!
  state_set_done INVENTORY_USER
done


# Order DB Link

while ! state_done ORDER_PROPAGATION; do
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@${SVC}_tp

create database link $LINK connect to $TU  identified by "$DB_PASSWORD" using '$TSVC';

!
  state_set_done ORDER_PROPAGATION
done

# Inventory DB Link

while ! state_done INVENTORY_PROPAGATION; do
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  TU=$ORDER_USER
  TSVC=$ORDER_DB_SVC
  LINK=$INVENTORY_LINK
  Q=$INVENTORY_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1

connect $U/"$DB_PASSWORD"@${SVC}_tp

create database link $LINK connect to $TU  identified by "$DB_PASSWORD" using '$TSVC';

!
  state_set_done INVENTORY_PROPAGATION
done


# Order Queues and Propagation
while ! state_done ORDER_PROPAGATION; do
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@{SVC}_tp
BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'$Q',
   subscriber=>sys.aq\$_agent(null,'$TU.$Q@$LINK',0),
   queue_to_queue => true);
END;
/

BEGIN
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
  state_set_done ORDER_PROPAGATION
done


# Inventory Queues and Propagation
while ! state_done INVENTORY_PROPAGATION; do
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  TU=$ORDER_USER
  TSVC=$ORDER_DB_SVC
  LINK=$INVENTORY_LINK
  Q=$INVENTORY_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@${SVC}_tp
BEGIN
DBMS_AQADM.add_subscriber(
   queue_name=>'$Q',
   subscriber=>sys.aq\$_agent(null,'$TU.$Q@$LINK',0),
   queue_to_queue => true);
END;
/

BEGIN
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
  state_set_done INVENTORY_PROPAGATION
done


# .net Inventory DB Proc
while ! state_done DOT_NET_INVENTORY_DB_PROC; do
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@${SVC}_tp
@$GRABDISH_HOME/inventory-dotnet/dequeueenqueue.sql
!
  state_set_done DOT_NET_INVENTORY_DB_PROC
done


# DB Setup Done
state_set_done DB_SETUP

