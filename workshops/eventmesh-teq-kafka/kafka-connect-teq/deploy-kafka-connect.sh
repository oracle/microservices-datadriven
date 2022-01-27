#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Collect the DB password
#echo "Please enter Oracle DB Password: "
#IFS= read -s -r -p ORACLE_DB_PASSWORD
read -s -r -p "Please enter Oracle DB Password: " ORACLE_DB_PASSWORD

# Collect the Kafka Topic to be consumed by Connect
read -p "Please enter the Kafka Topic: " KAFKA_TOPIC

jq '.topics |= "$KAFKA_TOPIC"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json

# Collect the DB USER
while ! state_done LAB_DB_USER; do
  LAB_DB_USER="$(state_get LAB_DB_USER)"
  jq '.java.naming.security.principal |= "$LAB_DB_USER"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
  mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json
done

# Collect Oracle Database Service
while ! state_done LAB_DB_NAME; do
  LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"
  jq '.java.naming.provider.url |= "jdbc:oracle:thin:@${LAB_DB_SVC}?TNS_ADMIN=/home/appuser/wallet"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
  jq '.db_url |= "jdbc:oracle:thin:@${LAB_DB_SVC}?TNS_ADMIN=/home/appuser/wallet"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json
done

# Collect the Oracle TEQ Topic (Destination)
while ! state_done LAB_TEQ_TOPIC; do
  LAB_TEQ_TOPIC="$(state_get LAB_TEQ_TOPIC)"
  jq '.jms.destination.name |= "$LAB_TEQ_TOPIC"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
  mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json
done

# Setup the Oracle DB User Password
jq '.java.naming.security.credentials |= "$ORACLE_DB_PASSWORD"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json

# Configure the Kafka Connect Sync with Oracle Database
curl -i -X PUT -H "Accept:application/json" \
    -H  "Content-Type:application/json" http://localhost:8083/connectors/"${LAB_DB_NAME}"_"${LAB_TEQ_TOPIC}"/config \
    -T kafka-connect-configuration.json

# Reset the Oracle DB User Password
jq '.java.naming.security.credentials |= "ORACLE_DB_PASSWORD"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json