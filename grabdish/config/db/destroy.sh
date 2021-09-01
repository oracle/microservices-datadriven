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
# OUTPUTS:
# output.env removed

set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit 1
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit 1
fi


# Check if we are already done
if ! test -f $MY_HOME/output.env; then
  exit 1
fi


source "$MY_HOME"/state.env


BUCKET_NAME=$RUN_NAME
# Create Object Store Bucket (Should be replaced by terraform one day)
oci os bucket delete --compartment-id "$COMPARTMENT_OCID" --name $BUCKET_NAME

PARIDS=`oci os preauth-request list --bucket-name "$BUCKET_NAME" --query "join(' ',data[*].id)" --raw-output`
for id in $PARIDS; do
    oci os preauth-request delete --par-id "$id" --bucket-name "$BUCKET_NAME" --force
done
 
# Object
oci os object delete --object-name "cwallet.sso" --bucket-name "$BUCKET_NAME" --force

# Bucket
oci os bucket delete --force --bucket-name "$BUCKET_NAME" --force

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
DELETE USER $U;
!


# Inventory DB User, Objects
U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC
sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC
DELETE USER $U;
!


rm -rf $MY_HOME/*