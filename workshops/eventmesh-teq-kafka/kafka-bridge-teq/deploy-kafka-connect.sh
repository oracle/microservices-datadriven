#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Collect the DB password
echo "Please enter Oracle DB Password: "
IFS= read -s -r -p ORACLE_DB_PASSWORD
ORACLE_DB_PASSWORD_BASE64=$(echo -n "$ORACLE_DB_PASSWORD" | base64)

# Collect the Kafka Topic to be consumed by Connect
echo "Please enter the Kafka Topic: "
IFS= read -r KAFKA_TOPIC

# Collect the DB USER
LAB_DB_USER="$(state_get LAB_DB_USER)"

# Collect Oracle Database Service
LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"
jq '.java.naming.provider.url |= "jdbc:oracle:thin:@${LAB_DB_SVC}?TNS_ADMIN=/home/appuser/wallet"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json

# Collect the Oracle TEQ Topic (Destination)
LAB_TEQ_TOPIC="$(state_get LAB_TEQ_TOPIC)"
jq '.topics |= "$LAB_TEQ_TOPIC"' "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json > "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp
mv "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.tmp "${LAB_HOME}"/kafka-bridge-teq/kafka-connect-configuration.json

# Configure the Kafka Connect Sync with Oracle Database
curl -i -X PUT -H "Accept:application/json" \
    -H  "Content-Type:application/json" http://localhost:8083/connectors/JmsSink_lab8022t/config \
    -T kafka-connect-configuration.json