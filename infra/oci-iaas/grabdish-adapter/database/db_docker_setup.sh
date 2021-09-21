#/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

#added for on-premise

# DB Connection Setup
ORDER_DB_SVC=orders
INVENTORY_DB_SVC=inventory
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
ORDER_LINK=ORDERTOINVENTORYLINK
INVENTORY_LINK=INVENTORYTOORDERLINK
ORDER_QUEUE=ORDERQUEUE
INVENTORY_QUEUE=INVENTORYQUEUE


# Get DB Password
DB_PASSWORD="$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq --raw-output  '.grabdish_database_password')"

#DB_SEED_PASSWORD=Welcome123
DB_SEED_PASSWORD=$DB_PASSWORD


# Create Orders PDB
U=$ORDER_USER
SVC=${ORDER_DB_SVC}
echo "##########   Creating Orders PDB ###########"
sqlplus sys/$DB_SEED_PASSWORD@$(hostname):1521/orcl as SYSDBA <<!
alter pluggable database ${SVC} close immediate instances=all;
drop pluggable database ${SVC}  including datafiles;
CREATE PLUGGABLE DATABASE ${SVC}
ADMIN USER admin IDENTIFIED BY "${DB_PASSWORD}"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '/opt/oracle/oradata/ORCL/${SVC}/$SVC01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '/opt/oracle/oradata/ORCL/dbs/${SVC}/'
FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCL/pdbseed/', '/opt/oracle/oradata/ORCL/${SVC}/');

alter pluggable database ${SVC}  open;

alter session set container=$SVC;
GRANT ALL PRIVILEGES TO admin


!

# Create Inventory PDB
U=$INVENTORY_USER
SVC=${INVENTORY_DB_SVC}
echo "##########   Creating Inventory PDB ###########"
#sqlplus /nolog <<!
sqlplus sys/$DB_SEED_PASSWORD@$(hostname):1521/orcl as SYSDBA <<!
alter pluggable database ${SVC} close immediate instances=all;
drop pluggable database ${SVC}  including datafiles;
CREATE PLUGGABLE DATABASE ${SVC}
ADMIN USER admin IDENTIFIED BY "${DB_PASSWORD}"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '/opt/oracle/oradata/ORCL/${SVC}/$SVC01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '/opt/oracle/oradata/ORCL/dbs/${SVC}/'
FILE_NAME_CONVERT = ('/opt/oracle/oradata/ORCL/pdbseed/', '/opt/oracle/oradata/ORCL/${SVC}/');

alter pluggable database ${SVC}  open;

alter session set container=$SVC;
GRANT ALL PRIVILEGES TO admin

!

#update Oracle listeners file

echo "##########  Reloading Database Listeners  ###########"
#lsnrctl reload

echo "##########   Granting Access to Order User, Creating Order PDB Queues  ###########"
# Order DB User, Objects


U=$ORDER_USER
SVC=$ORDER_DB_SVC

echo "admin"/"$DB_PASSWORD"@${SVC}_tp

sqlplus "sys"/"$DB_PASSWORD"@${SVC}_tp as sysdba <<!
WHENEVER SQLERROR EXIT 1
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD";
GRANT pdb_dba TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;

GRANT SODA_APP to $U;

/
!



sqlplus $U/"$DB_PASSWORD"@${SVC}_tp <<!

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


echo "##########   Granting Access to Inventory User, Creating Inventory PDB Queues  ###########"
echo $U/"$DB_PASSWORD"@${SVC}_tp
echo "#############DEBUGGING"


# Inventory DB User, Objects

  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
echo "##########   Granting Access to Inventory User, Creating Inventory PDB Queues  ###########"
echo $U/"$DB_PASSWORD"@${SVC}_tp
echo "#############DEBUGGING"
  #connect admin/"$DB_PASSWORD"@$SVC
#  sqlplus /nolog <<!
sqlplus "sys"/"$DB_PASSWORD"@${SVC}_tp as sysdba <<!
WHENEVER SQLERROR EXIT 1
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

echo "##########   Created Inventory TABLESPACE  ###########"

echo "##########   Creating DB Links for Orders  ###########"


# Order DB Link

  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@${SVC}_tp


create database link $LINK connect to $TU  identified by "$DB_PASSWORD" using '${TSVC}_tp';


!

# Inventory DB Link
echo "##########   Creating DB Links for Inventory  ###########"


  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  TU=$ORDER_USER
  TSVC=$ORDER_DB_SVC
  LINK=$INVENTORY_LINK
  Q=$INVENTORY_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1

connect $U/"$DB_PASSWORD"@${SVC}_tp

create database link $LINK connect to $TU  identified by "$DB_PASSWORD" using '${TSVC}_tp';


!

echo "##########   Creating  Order Queues and Propagation  ###########"


# Order Queues and Propagation

  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
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

echo "##########   Creating  Inventory Queues and Propagation  ###########"

# Inventory Queues and Propagation

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

echo "##########   .net Inventory DB Proc  ###########"

# .net Inventory DB Proc

U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@${SVC}_tp
@$GRABDISH_HOME/inventory-dotnet/dequeueenqueue.sql
!

# DB Setup Done
state_set_done DB_SETUP



