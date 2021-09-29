#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


export GRABDISH_LOG


# Useful variables
ORDER_DB_SVC="$ORDER_DB_ALIAS"
INVENTORY_DB_SVC="$INVENTORY_DB_ALIAS"
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER
DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)


# Inventory User
while test -f $MY_STATE/inventory_user; do
  export TNS_ADMIN=$INVENTORY_DB_TNS_ADMIN
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  if sqlplus /nolog; then
    rm -f $MY_STATE/inventory_plsql_proc $MY_STATE/inventory_prop $MY_STATE/inventory_db_link rm $MY_STATE/inventory_user
  else
    echo "Failed to remove inventory schema.  Retrying..."
    sleep 10
  fi <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
DROP USER $U CASCADE;
!
done


# Order User
while test -f $MY_STATE/order_user; do
  export TNS_ADMIN=$ORDER_DB_TNS_ADMIN
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  if sqlplus /nolog; then
    rm -f $MY_STATE/order_prop $MY_STATE/order_db_link $MY_STATE/order_user
  else
    echo "Failed to remove order schema.  Retrying..."
    sleep 10
  fi <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
DROP USER $U CASCADE;
!
done


# Inventory DB Connection Setup
if test -f $MY_STATE/inventorydb_tns_admin; then
  rm $MY_STATE/inventorydb_tns_admin
fi


# Order DB Connection Setup
if test -f $MY_STATE/orderdb_tns_admin; then
  rm $MY_STATE/orderdb_tns_admin
fi


rm -f $STATE_FILE