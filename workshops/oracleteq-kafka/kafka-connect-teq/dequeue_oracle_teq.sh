#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage: 'source dequeue_oracle_teq.sh"
  exit
fi

# Collect the DB password
read -s -r -p "Please enter Oracle DB Password: " ORACLE_DB_PASSWORD
echo "***********"

# Collect the DB USER
if state_done LAB_DB_USER; then
  LAB_DB_USER="$(state_get LAB_DB_USER)"
else
  echo "ERROR: Oracle DB user is missing!"
  exit
fi

# Collect Oracle Database Service
if state_done LAB_DB_NAME; then
  LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"
else
  echo "ERROR: Oracle DB Service is missing!"
  exit
fi

# Collect the Oracle TEQ Topic (Destination)
if state_done LAB_TEQ_TOPIC; then
  TEQ_TOPIC="$(state_get LAB_TEQ_TOPIC)"
else
  echo "ERROR: Oracle TEQ Topic is missing!"
  exit
fi

# Collect the Oracle TEQ Subscriber (Destination)
if state_done LAB_TEQ_TOPIC_SUBSCRIBER; then
  TEQ_SUBSCRIBER="$(state_get LAB_TEQ_TOPIC_SUBSCRIBER)"
else
  echo "ERROR: Oracle TEQ Topic Subscriber is missing!"
  exit
fi

# DB Connection Setup
export TNS_ADMIN=$LAB_HOME/wallet

# DEQUEUE TEQ Message
sql -S /nolog <<!
  connect $LAB_DB_USER/"$ORACLE_DB_PASSWORD"@$LAB_DB_SVC

  @dequeue_msg_oracle_teq_topic.sql $TEQ_TOPIC $TEQ_SUBSCRIBER

  exit;
!