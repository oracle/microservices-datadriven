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

# Create the ext-order service
cd $GRABDISH_HOME/order-helidon; 
kubectl apply -f ext-order-ingress.yaml -n msdataworkshop

# Install k6
cd $GRABDISH_HOME/k6; 
if ! test -f k6; then
  wget https://github.com/loadimpact/k6/releases/download/v0.27.0/k6-v0.27.0-linux64.tar.gz; 
  tar -xzf k6-v0.27.0-linux64.tar.gz; 
  ln k6-v0.27.0-linux64/k6 k6
fi

# Get LB (may have to retry)
RETRIES=0
while ! state_done EXT_ORDER_IP; do
  #IP=`kubectl get services -n msdataworkshop | awk '/ext-order/ {print $4}'`
  IP=$(kubectl -n msdataworkshop get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
  if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set EXT_ORDER_IP "$IP"
  else
    RETRIES=$(($RETRIES + 1))
    echo "Waiting for EXT_ORDER IP"
    if test $RETRIES -gt 24; then
      echo "ERROR: Failed to get EXT_ORDER_IP"
      exit
    fi
    sleep 5
  fi
done


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


  # Create a large number of orders
  cd $GRABDISH_HOME/k6; 
  export LB=$(state_get EXT_ORDER_IP)
  ./test-perf.sh $ORDER_COUNT

  # Add the inventory
  export TNS_ADMIN=$GRABDISH_HOME/wallet
  INVENTORY_DB_SVC="$(state_get INVENTORY_DB_NAME)_tp"
  INVENTORY_USER=INVENTORYUSER
  DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`
  U=$INVENTORY_USER
  SVC=$INVENTORY_DB_SVC
  sqlplus /nolog <<!

connect $U/"$DB_PASSWORD"@$SVC
update inventory set inventorycount=$ORDER_COUNT;
commit;
!


  # Deploy the test subject
  cd $GRABDISH_HOME/$s
  ./deploy.sh

  if test "$s" != 'inventory-plsql'; then # PL/SQL service is not deployed in k8s and starts immediately
    while test 1 -gt `kubectl get pods -n msdataworkshop | grep "${s}" | grep "1/1" | wc -l`; do
      /bin/sleep 0.1
    done
  fi

  START_TIME=`date`
  START_NANOSECONDS="$(date +%s%N)"
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
    /bin/sleep 0.1
  done

  END_TIME=`date`
  END_NANOSECONDS="$(date +%s%N)"
  echo "PERF_LOG: $s Processing completed at $END_TIME"
  echo "PERF_LOG_STAT: $s Processed $ORDER_COUNT orders in $((($END_NANOSECONDS-$START_NANOSECONDS)/1000000)) milliseconds"

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