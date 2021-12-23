 #!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Create Object Store Bucket (Should be replaced by terraform one day)
while ! state_done OBJECT_STORE_BUCKET; do
  oci os bucket create --compartment-id "$(state_get COMPARTMENT_OCID)" --name "$(state_get RUN_NAME)"
  state_set_done OBJECT_STORE_BUCKET
done


# Wait for Order DB OCID
while ! state_done ORDER_DB_OCID; do
  echo "`date`: Waiting for ORDER_DB_OCID"
  sleep 2
done


# Wait for Inventory DB OCID
while ! state_done INVENTORY_DB_OCID; do
  echo "`date`: Waiting for INVENTORY_DB_OCID"
  sleep 2
done


# Get Wallet
while ! state_done WALLET_GET; do
  cd $GRABDISH_HOME
  mkdir wallet
  cd wallet
  oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get ORDER_DB_OCID)" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
  unzip wallet.zip
  cd $GRABDISH_HOME
  state_set_done WALLET_GET
done


# Get DB Connection Wallet and to Object Store
while ! state_done CWALLET_SSO_OBJECT; do
  cd $GRABDISH_HOME/wallet
  oci os object put --bucket-name "$(state_get RUN_NAME)" --name "cwallet.sso" --file 'cwallet.sso'
  cd $GRABDISH_HOME
  state_set_done CWALLET_SSO_OBJECT
done


# Create Authenticated Link to Wallet
while ! state_done CWALLET_SSO_AUTH_URL; do
  ACCESS_URI=`oci os preauth-request create --object-name 'cwallet.sso' --access-type 'ObjectRead' --bucket-name "$(state_get RUN_NAME)" --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
  state_set CWALLET_SSO_AUTH_URL "https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"
done


# Give DB_PASSWORD priority
while ! state_done DB_PASSWORD; do
  echo "Waiting for DB_PASSWORD"
  sleep 5
done


# Create Inventory ATP Bindings
while ! state_done DB_WALLET_SECRET; do
  cd $GRABDISH_HOME/wallet
  cat - >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="/msdataworkshop/creds")))
SSL_SERVER_DN_MATCH=yes
!
  if kubectl create -f - -n msdataworkshop; then
    state_set_done DB_WALLET_SECRET
  else
    echo "Error: Failure to create db-wallet-secret.  Retrying..."
    sleep 5
  fi <<!
apiVersion: v1
data:
  README: $(base64 -w0 README)
  cwallet.sso: $(base64 -w0 cwallet.sso)
  ewallet.p12: $(base64 -w0 ewallet.p12)
  keystore.jks: $(base64 -w0 keystore.jks)
  ojdbc.properties: $(base64 -w0 ojdbc.properties)
  sqlnet.ora: $(base64 -w0 sqlnet.ora)
  tnsnames.ora: $(base64 -w0 tnsnames.ora)
  truststore.jks: $(base64 -w0 truststore.jks)
kind: Secret
metadata:
  name: db-wallet-secret
!
  cd $GRABDISH_HOME
done


# DB Connection Setup
export TNS_ADMIN=$GRABDISH_HOME/wallet
cat - >$TNS_ADMIN/sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!

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


CONFIG_HOME=$GRABDISH_HOME/config/db


DB_DEPLOYMENT='1DB'
DB_TYPE=ATP

if test $DB_DEPLOYMENT == "1DB"; then
  # 1DB
  SCRIPT_HOME=$CONFIG_HOME/1db/apply
  ORDER_DB_TNS_ADMIN=$TNS_ADMIN
  INVENTORY_DB_TNS_ADMIN=$TNS_ADMIN
  ORDER_DB_ALIAS="$(state_get ORDER_DB_NAME)_tp"
  INVENTORY_DB_ALIAS="$(state_get ORDER_DB_NAME)_tp"
  state_set INVENTORY_DB_NAME "$(state_get ORDER_DB_NAME)"
  QUEUE_TYPE=teq
else
  # 2DB
  if test $DB_TYPE == "ATP"; then
    # ATP
    SCRIPT_HOME=$CONFIG_HOME/2db-atp/apply
    ORDER_DB_TNS_ADMIN=$TNS_ADMIN
    INVENTORY_DB_TNS_ADMIN=$TNS_ADMIN
    ORDER_DB_ALIAS="$(state_get ORDER_DB_NAME)_tp"
    INVENTORY_DB_ALIAS="$(state_get INVENTORY_DB_NAME)_tp"
    ORDER_DB_CWALLET_SSO_AUTH_URL="$(state_get CWALLET_SSO_AUTH_URL)"
    INVENTORY_DB_CWALLET_SSO_AUTH_URL="$(state_get CWALLET_SSO_AUTH_URL)"
    QUEUE_TYPE=stdq
  else
    # Standard Database
    SCRIPT_HOME=$CONFIG_HOME/2db-std/apply
    ORDER_DB_TNS_ADMIN=$TNS_ADMIN
    INVENTORY_DB_TNS_ADMIN=$TNS_ADMIN
    ORDER_DB_ALIAS="$(state_get ORDER_DB_NAME)_tp"
    INVENTORY_DB_ALIAS="$(state_get INVENTORY_DB_NAME)_tp"
    QUEUE_TYPE=teq
  fi
fi

source $CONFIG_HOME/params.env


# Wait for DB Password to be set in Order DB
while ! state_done ORDER_DB_PASSWORD_SET; do
  echo "`date`: Waiting for ORDER_DB_PASSWORD_SET"
  sleep 2
done


# Wait for DB Password to be set in Inventory DB
while ! state_done INVENTORY_DB_PASSWORD_SET; do
  echo "`date`: Waiting for INVENTORY_DB_PASSWORD_SET"
  sleep 2
done


# Expand common scripts
mkdir -p $COMMON_SCRIPT_HOME
files=$(ls $CONFIG_HOME/common)
for f in $files; do
  eval "
cat >$COMMON_SCRIPT_HOME/$f <<!
$(<$CONFIG_HOME/common/$f)
!
"
done


# Execute DB setup scripts
files=$(ls $SCRIPT_HOME)
for f in $files; do
  # Execute all the SQL scripts in order using the appropriate TNS_ADMIN
  db_number=`grep -oP '(?<=\d\d-db)\d(?=-)' <<<"$f"`
  echo "Executing $SCRIPT_HOME/$f on database DB$db_number"
  eval "
export TNS_ADMIN=\$DB${db_number}_TNS_ADMIN
sqlplus /nolog <<!
set echo on
$(<$SCRIPT_HOME/$f)
!
"
done

# DB Setup Done
state_set_done DB_SETUP