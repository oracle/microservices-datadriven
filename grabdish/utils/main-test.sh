#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "TEST_LOG_FAILED: This script requires GRABDISH_HOME to be set"
  exit
fi

# Check TEST_UI_PASSWORD is set
export TEST_UI_PASSWORD=`kubectl get secret frontendadmin -n msdataworkshop --template={{.data.password}} | base64 --decode`


echo 'TEST_LOG: #####################################'

# WALKTHROUGH
echo "TEST_LOG: #### Testing Lab2: Walkthrough Undeploy..."

# Undeploy to make it rerunable
./undeploy.sh
SERVICES="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se inventory-plsql inventory-springboot"
for s in $SERVICES; do
  cd $GRABDISH_HOME/$s
  ./undeploy.sh || true
done

# Wait for Pods to stop
while test 0 -lt `kubectl get pods -n msdataworkshop | egrep 'frontend-helidon|inventory-|order-helidon|supplier-helidon-se|inventory-springboot' | wc -l`; do
  echo "Waiting for pods to stop..."
  sleep 10
done

# Deploy the java services
echo "TEST_LOG: #### Testing Lab2: Walkthrough Deploy..."
cd $GRABDISH_HOME
./deploy.sh

while test 4 -gt `kubectl get pods -n msdataworkshop | egrep 'frontend-helidon|inventory-helidon|order-helidon|supplier-helidon-se' | grep "1/1" | wc -l`; do
  echo "Waiting for pods to start..."
  sleep 10
done

# Get the frontend URL
RETRIES=0
while ! state_done FRONTEND_URL; do
  IP=$(kubectl -n msdataworkshop get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
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


# Delete all order (to make it rerunable)
function deleteallorders() {
  echo '{"serviceName": "order", "commandName": "deleteallorders", "orderId": -1, "orderItem": "", "deliverTo": ""}'
}

if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(deleteallorders)" \
  --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/order; then
  echo "TEST_LOG: $TEST_STEP deleteallorders succeeded"
else
  echo "TEST_LOG_FAILED_FATAL: $TEST_STEP deleteallorders failed"
  exit
fi


# Functional test on order 66/67
utils/func-test.sh Walkthrough 66
logpodnotail frontend > $GRABDISH_LOG/testlog-frontend-from-Walkthrough
logpodnotail supplier > $GRABDISH_LOG/testlog-supplier-from-Walkthrough
logpodnotail order > $GRABDISH_LOG/testlog-order-from-Walkthrough
logpodnotail inventory > $GRABDISH_LOG/testlog-inventory-from-Walkthrough


# POLYGLOT
echo "TEST_LOG: #### Testing Lab3: Polyglot"
# Deploy each inventory service and perform functional test
#while ! $(state_get NON_JAVA_BUILDS); do
#  sleep 10
#  echo "Waiting for NON_JAVA_BUILDS"
#done

utils/polyglot-test.sh
echo writing log to $GRABDISH_LOG/testlog-frontend-from-polyglot
logpodnotail frontend > $GRABDISH_LOG/testlog-frontend-from-polyglot
logpodnotail supplier > $GRABDISH_LOG/testlog-supplier-from-polyglot
logpodnotail order > $GRABDISH_LOG/testlog-order-from-polyglot

## SCALING
echo "TEST_LOG: #### Testing Lab4: Scaling"
utils/scaling-test.sh
#
#
## TRACING
#echo "TEST_LOG: #### Testing Lab5: Tracing"
#utils/tracing-test.sh


# APEX
# TODO


# TRANSACTIONAL
echo "TEST_LOG: #### Testing Lab7: Transactional Tests: Compare MongoDB, Postgres, and Kafka to Oracle DB with TEQ/AQ"
utils/crashrecovery-test.sh

# TEARDOWN
# source destroy.sh
