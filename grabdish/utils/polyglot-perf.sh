#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Deploy each inventory service and perform perf test
SERVICES="inventory-helidon inventory-dotnet inventory-go inventory-python inventory-nodejs inventory-helidon-se inventory-plsql"
ORDER_COUNT=1000

# Delete all orders payload
function deleteallorders() {
echo '{"serviceName": "order", "commandName": "deleteallorders", "orderId": -1, "orderItem": "", "deliverTo": ""}'
}

function order() {
  echo '{"serviceName": "order", "commandName": "'"$2"'", "orderId": '"$1"', "orderItem": "sushi", "deliverTo": "780 PANORAMA DR, San francisco, CA"}'
}

function inventory() {
  echo '{"serviceName": "supplier", "commandName": "'"$2"'", "orderId": -1, "orderItem": "'"$1"'", "deliverTo": ""}'
}

function placeOrderTest() {
  # Place order
  local ORDER_ID="$1"
  if ! wget -q --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(order "$ORDER_ID" 'placeOrder')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/placeorder" -O $GRABDISH_LOG/order &>/dev/null;
  then
    echo "PERF_LOG_FAILED_FATAL: placeOrder $ORDER_ID failed"
    exit
  fi
}

function addInventoryTest() {
  # Add inventory 
  local ITEM_ID="$1"
  if ! wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(inventory "$ITEM_ID" 'addInventory')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/inventory &>/dev/null; 
  then
    echo "PERF_LOG_FAILED_FATAL: addInventory $ITEM_ID request failed"
    exit
  fi
}


for s in $SERVICES; do
  echo "PERF_LOG: Testing $s"

  # Delete all order (to refresh)
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(deleteallorders)" \
  --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/order &>/dev/null; 
  then
    echo "PERF_LOG: $s deleteallorders succeeded"
  else
    echo "PERF_LOG_FAILED_FATAL: $s deleteallorders failed"
    exit
  fi


  # Create a large number of orders and inventory
  echo "PERF_LOG: $s adding $ORDER_COUNT orders and inventory"
  for ((ORDER_ID=1; ORDER_ID<=$ORDER_COUNT; ORDER_ID++)) 
  do
    placeOrderTest "$ORDER_ID"
    addInventoryTest "sushi"
  done


  # Deploy the test subject
  cd $GRABDISH_HOME/$s
  ./deploy.sh

  if test "$s" != 'inventory-plsql'; then # PL/SQL service is not deployed in k8s and starts immediately
    while test 1 -gt `kubectl get pods -n msdataworkshop | grep "${s}" | grep "1/1" | wc -l`; do
      echo "Waiting for pod to start..."
      sleep 1
    done
  fi

  START_TIME=`date`
  START_SECONDS="$(date -u +%s)"
  echo "PERF_LOG: $s Processing started at $START_TIME"

  # Monitor to see how long it takes to consume all the inventory
  while true;
  do
    if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(inventory sushi 'getInventory')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/inventory &>/dev/null; 
    then
      if grep "inventorycount for sushi is now 0" $GRABDISH_LOG/inventory >/dev/null; then
        break
      fi
    else
      echo "PERF_LOG_FAILED_FATAL: $s Failed to get inventory count"
      exit
    fi
    sleep 1
  done

  END_TIME=`date`
  END_SECONDS="$(date -u +%s)"
  echo "PERF_LOG: $s Processing completed at $END_TIME"
  echo "PERF_LOG: $s Processed $ORDER_COUNT orders in $(($END_SECONDS-$START_SECONDS)) seconds"

  logpodnotail inventory > $GRABDISH_LOG/perflog-$s

  # Undeploy the test subject
  cd $GRABDISH_HOME/$s
  ./undeploy.sh

  # Wait for Pod to stop
  while test 0 -lt `kubectl get pods -n msdataworkshop | egrep 'inventory-' | wc -l`; do
    echo "Waiting for pod to stop..."
    sleep 5
  done

done