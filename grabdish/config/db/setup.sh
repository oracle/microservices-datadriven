#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   OCI CLI (configured)
#   sqlplus
#   GRABDISH_HOME (set)
#
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
# input.env
#   COMPARTMENT_OCID
#   ORDERDB_TNS_ADMIN
#   ORDERDB_ALIAS
#   INVENTORYDB_ALIAS
#   REGION
#
# OUTPUTS:
# output.env
#   <empty indicates done>


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit
fi


# Source input.env
if test -f $MY_HOME/output.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit
fi


BUCKET_NAME=grabdish-cwallet
# Create Object Store Bucket (Should be replaced by terraform one day)
oci os bucket create --compartment-id "$COMPARTMENT_OCID" --name $BUCKET_NAME


# Get DB Connection Wallet and to Object Store
cd $ORDERDB_TNS_ADMIN
oci os object put --bucket-name $BUCKET_NAME --name "cwallet.sso" --file 'cwallet.sso'


# Create Authenticated Link to Wallet
ACCESS_URI=`oci os preauth-request create --object-name 'cwallet.sso' --access-type 'ObjectRead' --bucket-name $BUCKET_NAME --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
CWALLET_SSO_AUTH_URL="https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"


# DB Connection Setup
export TNS_ADMIN=$ORDERDB_TNS_ADMIN
cat - >$TNS_ADMIN/sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!
ORDER_DB_SVC="$ORDERDB_ALIAS"
INVENTORY_DB_SVC="$INVENTORYDB_ALIAS"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
ORDER_LINK=ORDERTOINVENTORYLINK
INVENTORY_LINK=INVENTORYTOORDERLINK
ORDER_QUEUE=ORDERQUEUE
INVENTORY_QUEUE=INVENTORYQUEUE
DB_PASSWORD=$(get_secret DB_PASSWORD)


U=$ORDER_USER
SVC=$ORDER_DB_SVC
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD";
GRANT pdb_dba TO $U;
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO $U;
GRANT EXECUTE ON DBMS_CLOUD TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;

GRANT SODA_APP to $U;

connect $U/"$DB_PASSWORD"@$SVC

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


# Inventory DB User, Objects
U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD";
GRANT pdb_dba TO $U;
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO $U;
GRANT EXECUTE ON DBMS_CLOUD TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;

connect $U/"$DB_PASSWORD"@$SVC

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


# Order DB Link
U=$ORDER_USER
SVC=$ORDER_DB_SVC
TU=$INVENTORY_USER
TSVC=$INVENTORY_DB_SVC
TTNS=`grep -i "^$TSVC " $TNS_ADMIN/tnsnames.ora`
LINK=$ORDER_LINK
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC
BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$CWALLET_SSO_AUTH_URL',
    directory_name => 'DATA_PUMP_DIR');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$TU',
    password => '$DB_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$LINK',
    hostname => '`grep -oP '(?<=host=).*?(?=\))' <<<"$TTNS"`',
    port => '`grep -oP '(?<=port=).*?(?=\))' <<<"$TTNS"`',
    service_name => '`grep -oP '(?<=service_name=).*?(?=\))' <<<"$TTNS"`',
    ssl_server_cert_dn => '`grep -oP '(?<=ssl_server_cert_dn=\").*?(?=\"\))' <<<"$TTNS"`',
    credential_name => 'CRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
!


# Inventory DB Link
U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
TU=$ORDER_USER
TSVC=$ORDER_DB_SVC
TTNS=`grep -i "^$TSVC " $TNS_ADMIN/tnsnames.ora`
LINK=$INVENTORY_LINK
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC
BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$CWALLET_SSO_AUTH_URL',
    directory_name => 'DATA_PUMP_DIR');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$TU',
    password => '$DB_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$LINK',
    hostname => '`grep -oP '(?<=host=).*?(?=\))' <<<"$TTNS"`',
    port => '`grep -oP '(?<=port=).*?(?=\))' <<<"$TTNS"`',
    service_name => '`grep -oP '(?<=service_name=).*?(?=\))' <<<"$TTNS"`',
    ssl_server_cert_dn => '`grep -oP '(?<=ssl_server_cert_dn=\").*?(?=\"\))' <<<"$TTNS"`',
    credential_name => 'CRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
!


# Order Queues and Propagation
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


# Inventory Queues and Propagation
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
U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC
@$GRABDISH_HOME/inventory-dotnet/dequeueenqueue.sql
!


touch $MY_HOME/output.env