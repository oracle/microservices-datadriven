#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


cd $MY_CODE/../..
export GRABDISH_HOME=$PWD
export GRABDISH_LOG


# Order DB Connection Setup
cat - >$ORDER_DB_TNS_ADMIN/sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$ORDER_DB_TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!


# Inventory DB Connection Setup
cat - >$INVENTORY_DB_TNS_ADMIN/sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$INVENTORY_DB_TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!


# Useful variables
ORDER_DB_SVC="$ORDER_DB_ALIAS"
INVENTORY_DB_SVC="$INVENTORY_DB_ALIAS"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)


# Inventory User
if test -f $MY_STATE/inventory_user; then
  export TNS_ADMIN=$INVENTORY_DB_TNS_ADMIN
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
DROP USER $U CASCADE;
!
  rm -f $MY_STATE/inventory_plsql_proc $MY_STATE/inventory_prop $MY_STATE/inventory_db_link rm $MY_STATE/inventory_user
fi


# Order User
if test -f $MY_STATE/order_user; then
  export TNS_ADMIN=$ORDER_DB_TNS_ADMIN
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
DROP USER $U CASCADE;
!
  rm -f $MY_STATE/order_prop $MY_STATE/order_db_link $MY_STATE/order_user
fi


# Inventory DB Connection Setup
if test -f $MY_STATE/inventorydb_tns_admin; then
  rm $MY_STATE/inventorydb_tns_admin
fi


# Order DB Connection Setup
if test -f $MY_STATE/orderdb_tns_admin; then
  rm $MY_STATE/orderdb_tns_admin
fi


rm -f $STATE_FILE