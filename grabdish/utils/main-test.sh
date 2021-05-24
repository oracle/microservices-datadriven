#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi

if ! state_done SETUP_VERIFIED; then
  echo "SETUP is incomplete"
  return 1
fi

# Check TEST_UI_PASSWORD is set
export TEST_UI_PASSWORD=`kubectl get secret frontendadmin -n msdataworkshop --template={{.data.password}} | base64 --decode`


echo 'TEST_LOG: #####################################'

# WALKTHROUGH
# Deploy the java services
echo "TEST_LOG: #### Testing Lab2: Walkthrough"
./deploy.sh

while test 4 -gt `kubectl get pods -n msdataworkshop | egrep 'frontend-helidon|inventory-helidon|order-helidon|supplier-helidon-se' | grep "1/1" | wc -l`; do
  echo "Waiting for pods to start..."
  sleep 10
done

# Get the frontend URL
RETRIES=0
while ! state_done FRONTEND_URL; do
  IP=`kubectl get services -n msdataworkshop | awk '/frontend/ {print $4}'`
  if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set FRONTEND_URL "https://$IP"
  else
    RETRIES=$(($RETRIES + 1))
    if test $RETRIES -gt 10; then
      echo "ERROR: Failed to get FRONTEND_URL"
      exit
    fi
    sleep 5
  fi
done


# Is the UI available?
if wget -qO- --no-check-certificate --http-user grabdish --http-password "$TEST_UI_PASSWORD" "$(state_get FRONTEND_URL)" | grep 'GrabDish Explorer' >/dev/null; then
  echo "TEST_LOG: Frontend UI Available"
else
  echo "TEST_LOG_FAILED: Frontend UI Unavailable"
  exit
fi

# Functional test on order 66/67
utils/func-test.sh Walkthrough 66


# POLYGLOT
echo "TEST_LOG: #### Testing Lab3: Polyglot"

# Deploy each inventory service and perform functional test
while ! $(state_get NON_JAVA_BUILDS); do
  sleep 10
  echo "Waiting for NON_JAVA_BUILDS"
done

utils/polyglot-test.sh


# SCALING
echo "TEST_LOG: #### Testing Lab4: Scaling"
utils/scaling-test.sh


# TRACING
echo "TEST_LOG: #### Testing Lab5: Tracing"
utils/tracing-test.sh


# APEX
# TODO


# TEARDOWN
# source destroy.sh
