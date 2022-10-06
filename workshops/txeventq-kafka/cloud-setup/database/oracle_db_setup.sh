#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Wait for Lab DB OCID
while ! state_done LAB_DB_OCID; do
  echo "$(date): Waiting for LAB_DB_OCID"
  sleep 2
done

# Give DB_PASSWORD priority
while ! state_done DB_PASSWORD; do
  echo "Waiting for DB_PASSWORD"
  sleep 5
done

# Wait for DB Password to be set in Lab DB
while ! state_done LAB_DB_PASSWORD_SET; do
  echo "$(date): Waiting for LAB_DB_PASSWORD_SET"
  sleep 2
done

# Get DB Password
DB_PASSWORD=$(state_get BASE64_DB_PASSWORD | base64 --decode)
state_reset BASE64_DB_PASSWORD

# Generate a wallet password
# Variable is not exported
WALLET_PASSWORD=$DB_PASSWORD

# Get Wallet
while ! state_done WALLET_GET; do
  cd "$LAB_HOME"
  mkdir wallet
  cd wallet
  umask 177
  echo '{"password": "'"$WALLET_PASSWORD"'"}' > temp_params
  umask 22
  #oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get LAB_DB_OCID)" --file 'wallet.zip' --password $WALLET_PASSWORD --generate-type 'S'
  oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get LAB_DB_OCID)" --generate-type 'SINGLE' --file 'wallet.zip' --from-json "file://temp_params"
  rm temp_params
  unzip -oq wallet.zip
  cd "$LAB_HOME"
  state_set_done WALLET_GET
done

# Create Object Store Bucket
while ! state_done OBJECT_STORE_BUCKET; do
  oci os bucket create --compartment-id "$(state_get COMPARTMENT_OCID)" --name "$(state_get RUN_NAME)"
  state_set_done OBJECT_STORE_BUCKET
done

# Get DB Connection Wallet and to Object Store
while ! state_done CWALLET_SSO_OBJECT; do
  cd "$LAB_HOME"/wallet
  oci os object put --bucket-name "$(state_get RUN_NAME)" --name "cwallet.sso" --file 'cwallet.sso'
  cd "$LAB_HOME"
  state_set_done CWALLET_SSO_OBJECT
done


# Create Authenticated Link to Wallet
while ! state_done CWALLET_SSO_AUTH_URL; do
  ACCESS_URI=$(oci os preauth-request create --object-name 'cwallet.sso' --access-type 'ObjectRead' --bucket-name "$(state_get RUN_NAME)" --name 'lab' --time-expires "$(date '+%Y-%m-%d' --date '+7 days')" --query 'data."access-uri"' --raw-output)
  state_set CWALLET_SSO_AUTH_URL "https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"
done



state_set_done DB_WALLET_SECRET
# DB Connection Setup
export TNS_ADMIN=$LAB_HOME/wallet
cat - >"$TNS_ADMIN"/sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!
LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"

# Define Database User
LAB_DB_USER="$(state_get RUN_NAME)_USER"
echo "$(date): Oracle DB USER = $LAB_DB_USER"

# Define TxEventQ Topic
LAB_TXEVENTQ_TOPIC="$(state_get RUN_NAME)TOPIC"
echo "$(date): Oracle TxEventQ TOPIC = $LAB_TXEVENTQ_TOPIC"
state_set LAB_TXEVENTQ_TOPIC "$LAB_TXEVENTQ_TOPIC"

# Define TxEventQ Agent Subscriber (group-ip)
LAB_TXEVENTQ_TOPIC_SUBSCRIBER="$(state_get RUN_NAME)_SUBS"
echo "$(date): Oracle TxEventQ TOPIC Subscriber= $LAB_TXEVENTQ_TOPIC_SUBSCRIBER"
state_set LAB_TXEVENTQ_TOPIC_SUBSCRIBER "$LAB_TXEVENTQ_TOPIC_SUBSCRIBER"

# Lab DB User, Objects
while ! state_done LAB_DB_USER; do
  U=$LAB_DB_USER
  SVC=$LAB_DB_SVC
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect admin/"$DB_PASSWORD"@$SVC

--- USER SQL
CREATE USER $U IDENTIFIED BY "$DB_PASSWORD"  ;

--- GRANT User permissions.
GRANT pdb_dba TO $U;
GRANT CREATE SESSION TO $U;
GRANT RESOURCE TO $U;
GRANT CONNECT TO $U;
GRANT EXECUTE ANY PROCEDURE TO $U;
GRANT UNLIMITED TABLESPACE TO $U;

--- GRANT AQ
GRANT AQ_USER_ROLE TO $U;
GRANT SELECT_CATALOG_ROLE TO $U;
GRANT EXECUTE ON DBMS_AQADM TO $U;
GRANT EXECUTE on DBMS_AQ TO $U;
GRANT EXECUTE on DBMS_AQIN TO $U;
GRANT EXECUTE on DBMS_AQJMS TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;
GRANT EXECUTE ON sys.dbms_aqin TO $U;
GRANT EXECUTE ON sys.dbms_aqjms TO $U;

commit;
!
  state_set LAB_DB_USER "$LAB_DB_USER"
done

cd "$LAB_HOME"

# Setup User Login on Wallet
# run java_mkstore.sh in background
if ! state_get CWALLET_SSO_UPDATED; then
  echo "Executing java_mkstore.sh in the background"
  "$LAB_HOME"/cloud-setup/database/java_mkstore.sh -nologo -wrl "$LAB_HOME"/wallet -createCredential "$LAB_DB_SVC" "$LAB_DB_USER" &>> "$LAB_LOG"/mkstore.log  <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!
  state_set_done CWALLET_SSO_UPDATED
fi

# Setup DB Connection
if ! state_get LAB_DB_CONNECTION; then
  echo "Executing Database Connection setup for apps in the background."
  "$LAB_HOME"/cloud-setup/database/oracle_db_setup_conn.sh &>> "$LAB_LOG"/oracle_db_setup_conn.log &
fi

# DB Setup Done
state_set_done DB_SETUP