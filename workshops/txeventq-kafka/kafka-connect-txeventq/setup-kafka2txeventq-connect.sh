#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

CONF_FILE="${LAB_HOME}"/kafka-connect-txeventq/kafka2txeventq-connect-configuration.json

# Collect Oracle Database Service
if state_done LAB_DB_NAME; then
  LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"
else
  echo "ERROR: Oracle DB Service is missing!"
  exit 2
fi

# Collect the DB USER
if state_done LAB_DB_USER; then
  LAB_DB_USER="$(state_get LAB_DB_USER)"
else
  echo "ERROR: Oracle DB user is missing!"
  exit 2
fi

# Collect the Oracle TxEventQ Topic (Destination)
if state_get TXEVENTQ_TOPIC_NAME; then
  TXEVENTQ_TOPIC="$(state_get TXEVENTQ_TOPIC_NAME)"
else
  echo "ERROR: Oracle TxEventQ Topic is missing!"
  exit 2
fi

# Collect the KAFKA Topic (Source)
if state_get KAFKA_TOPIC_NAME; then
  KAFKA_TOPIC="$(state_get KAFKA_TOPIC_NAME)"
else
  echo "ERROR: KAFKA Topic is missing!"
  exit 2
fi

# Collect the DB password
read -s -r -p "Please enter Oracle DB Password: " ORACLE_DB_PASSWORD
echo "***********"

# DB Connection Setup
export TNS_ADMIN=$LAB_HOME/wallet

# Validate User/Password
user_is_valid=$(sqlplus -S /nolog <<!
  connect $LAB_DB_USER/"$ORACLE_DB_PASSWORD"@$LAB_DB_SVC
!
)

if [[ "$user_is_valid" == *"ORA-01017"* ]]; then
  echo "ERROR: invalid username/password."
  exit 2
fi

# Set the KAFKA TOPIC produced by Connect sync
sed -i 's/LAB_KAFKA_TOPIC/'"${KAFKA_TOPIC}"'/g' "$CONF_FILE"

# Set the Oracle Database User used by Connect Sync
sed -i 's/LAB_DB_USER/'"${LAB_DB_USER}"'/g' "$CONF_FILE"

# Setup the Oracle DB User Password
sed -i 's/LAB_DB_PASSWORD/'"${ORACLE_DB_PASSWORD}"'/g' "$CONF_FILE"

# Set the Oracle Database URL used by Connect Sync
sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$CONF_FILE"

# Set the Oracle TxEventQ TOPIC produced by Connect sync
sed -i 's/LAB_TXEVENTQ_TOPIC/'"${TXEVENTQ_TOPIC}"'/g' "$CONF_FILE"

# Configure the Kafka Connect Sync with Oracle Database
curl -S -s -o /dev/null \
     -i -X PUT -H "Accept:application/json" \
     -H "Content-Type:application/json" http://localhost:8083/connectors/JmsConnectSync_txeventqlab/config \
     -T "$CONF_FILE"

# Reset the Oracle DB User Password
jq '."java.naming.security.credentials" |= "ORACLE_DB_PASSWORD"' \
   "$CONF_FILE" > "$CONF_FILE"'_tmp'

mv "$CONF_FILE"'_tmp' "$CONF_FILE"