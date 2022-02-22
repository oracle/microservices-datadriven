#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

CONF_FILE="${LAB_HOME}"/kafka-connect-teq/kafka2teq-connect-configuration.json

# Collect the DB password
read -s -r -p "Please enter Oracle DB Password: " ORACLE_DB_PASSWORD
#seq  -f "*" -s '' -t '\n' "${#ORACLE_DB_PASSWORD}"

# Collect the Kafka Topic to be consumed by Connect
# read -r -p "Please enter Kafka Topic: " KAFKA_TOPIC

# Collect the DB USER
if state_get LAB_DB_USER; then
  LAB_DB_USER="$(state_get LAB_DB_USER)"

  # Set the Oracle Database User used by Connect Sync
  sed -i 's/LAB_DB_USER/'"${LAB_DB_USER}"'/g' "$CONF_FILE"
else
  echo "ERROR: Oracle DB user is missing!"
  exit
fi

# Collect Oracle Database Service
if state_get LAB_DB_NAME; then
  LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"

  # Set the Oracle Database URL used by Connect Sync
  sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$CONF_FILE"
else
  echo "ERROR: Oracle DB Service is missing!"
  exit
fi

# Collect the Oracle TEQ Topic (Destination)
if state_get LAB_TEQ_TOPIC; then
  TEQ_TOPIC="$(state_get LAB_TEQ_TOPIC)"

  # Set the Oracle TEQ TOPIC produced by Connect sync
  sed -i 's/LAB_TEQ_TOPIC/'"${TEQ_TOPIC}"'/g' "$CONF_FILE"
else
  echo "ERROR: Oracle TEQ Topic is missing!"
  exit
fi

# Setup the Oracle DB User Password
sed -i 's/LAB_DB_PASSWORD/'"${ORACLE_DB_PASSWORD}"'/g' "$CONF_FILE"

# Configure the Kafka Connect Sync with Oracle Database
curl -S -s -o /dev/null \
     -i -X PUT -H "Accept:application/json" \
     -H "Content-Type:application/json" http://localhost:8083/connectors/JmsConnectSync_lab8022/config \
     -T "$CONF_FILE"

# Reset the Oracle DB User Password
jq '."java.naming.security.credentials" |= "ORACLE_DB_PASSWORD"' \
   "$CONF_FILE" > "$CONF_FILE"'_tmp'

mv "$CONF_FILE"'_tmp' "$CONF_FILE"