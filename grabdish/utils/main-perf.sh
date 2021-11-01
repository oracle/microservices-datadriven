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

if ! state_done SETUP_VERIFIED; then
  echo "TEST_LOG_FAILED: Setup is incomplete"
  exit
fi

# Check TEST_UI_PASSWORD is set
export TEST_UI_PASSWORD=`kubectl get secret frontendadmin -n msdataworkshop --template={{.data.password}} | base64 --decode`


echo 'PERF_LOG: #####################################'

# Undeploy to make it rerunable
./undeploy.sh
SERVICES="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se inventory-plsql"
for s in $SERVICES; do
  cd $GRABDISH_HOME/$s
  ./undeploy.sh || true
done

# Wait for Pods to stop
while test 0 -lt `kubectl get pods -n msdataworkshop | egrep 'frontend-helidon|inventory-|order-helidon|supplier-helidon-se' | wc -l`; do
  echo "Waiting for pods to stop..."
  sleep 10
done

# Deploy the java services
SERVICES="frontend-helidon order-helidon supplier-helidon-se"
for s in $SERVICES; do
  cd $GRABDISH_HOME/$s
  ./deploy.sh || true
done

while test 3 -gt `kubectl get pods -n msdataworkshop | egrep 'frontend-helidon|order-helidon|supplier-helidon-se' | grep "1/1" | wc -l`; do
  echo "Waiting for pods to start..."
  sleep 10
done


# Get the frontend URL
RETRIES=0
while ! state_done FRONTEND_URL; do
  #IP=`kubectl get services -n msdataworkshop | awk '/frontend/ {print $4}'`
  IP=$(kubectl -n msdataworkshop get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
  if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set FRONTEND_URL "https://$IP"
  else
    RETRIES=$(($RETRIES + 1))
    if test $RETRIES -gt 10; then
      echo "PERF_LOG_FAILED: Failed to get FRONTEND_URL"
      exit
    fi
    sleep 5
  fi
done


# Is the UI available?
if wget -qO- --no-check-certificate --http-user grabdish --http-password "$TEST_UI_PASSWORD" "$(state_get FRONTEND_URL)" | grep 'GrabDish Explorer' >/dev/null; then
  echo "PERF_LOG: Frontend UI Available"
else
  echo "PERF_LOG_FAILED_FATAL: Frontend UI Unavailable"
  exit
fi


# Polyglot Background Inventory Processing
echo "PERF_LOG: #### Polyglot Background Inventory Processing"

while ! $(state_get NON_JAVA_BUILDS); do
  sleep 10
  echo "Waiting for NON_JAVA_BUILDS"
done

cd $GRABDISH_HOME
utils/polyglot-perf.sh
logpodnotail frontend > $GRABDISH_LOG/perflog-frontend-from-polyglot
logpodnotail supplier > $GRABDISH_LOG/perflog-supplier-from-polyglot
logpodnotail order > $GRABDISH_LOG/perflog-order-from-polyglot