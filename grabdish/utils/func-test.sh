#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

TEST_STEP="$1"
ORDER_ID="$2"
TEST_SERVICE="$3" #currently used solely to name log file

function order() {
  echo '{"serviceName": "order", "commandName": "'"$2"'", "orderId": '"$1"', "orderItem": "sushi", "deliverTo": "780 PANORAMA DR, San francisco, CA"}'
}

function inventory() {
  echo '{"serviceName": "supplier", "commandName": "'"$2"'", "orderId": -1, "orderItem": "'"$1"'", "deliverTo": ""}'
}

function placeOrderTest() {
  # Place order
  local ORDER_ID="$1"
  if wget -q --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(order "$ORDER_ID" 'placeOrder')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/placeorder" -O $GRABDISH_LOG/order; then
    echo "TEST_LOG: $TEST_STEP placeOrder $ORDER_ID succeeded"
  else
    echo "TEST_LOG_FAILED: $TEST_STEP placeOrder $ORDER_ID failed"
  fi
}

function showOrderTest() {
   # Show order 
  local ORDER_ID="$1"
  local SEARCH_FOR="$2"
  if wget -q --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(order "$ORDER_ID" 'showorder')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/order; then
    echo "TEST_LOG: $TEST_STEP showOrder request $1 succeeded"
    if grep "$SEARCH_FOR" $GRABDISH_LOG/order >/dev/null; then
      echo "TEST_LOG: $TEST_STEP showOrder $ORDER_ID matched '$SEARCH_FOR'"
    else
      echo "TEST_LOG_FAILED: $TEST_STEP showOrder $ORDER_ID expected '$SEARCH_FOR' but got... " | tr '\n' ' ' ;cat $GRABDISH_LOG/order
    fi
  else
    echo "TEST_LOG_FAILED: $TEST_STEP showOrder request $1 failed"
  fi
}

function verifyInventoryCountTest() {
  local ITEM_ID="$1"
  local SEARCH_FOR="$2"
  local ORDER_ID="$3"
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(inventory "$ITEM_ID" 'getInventory')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/inventory; then
    echo "TEST_LOG: $TEST_STEP verifyInventoryCountTest request $1 succeeded"
    if grep "$SEARCH_FOR" $GRABDISH_LOG/inventory >/dev/null; then
      echo "TEST_LOG: $TEST_STEP verifyInventoryCountTest $ITEM_ID after ORDER_ID $ORDER_ID expected inventory count: '$SEARCH_FOR'"
    else
      echo "TEST_LOG_FAILED: $TEST_STEP verifyInventoryCountTest $ITEM_ID after ORDER_ID $ORDER_ID unexpected inventory count, not '$SEARCH_FOR'" | tr '\n' ' ' ; cat $GRABDISH_LOG/inventory
      echo ...
    fi
  else
    echo "TEST_LOG_FAILED: $TEST_STEP verifyInventoryCountTest $ITEM_ID after ORDER_ID $ORDER_ID request $1 failed"
  fi
}

function addInventoryTest() {
  # Add inventory 
  local ITEM_ID="$1"
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(inventory "$ITEM_ID" 'addInventory')" \
    --header='Content-Type: application/json' "$(state_get FRONTEND_URL)/command" -O $GRABDISH_LOG/inventory; then
    echo "TEST_LOG: $TEST_STEP addInventory $ITEM_ID succeeded"
  else
    echo "TEST_LOG_FAILED: $TEST_STEP addInventory $ITEM_ID request failed"
  fi
}


# Show order and wait for status "no inventory"

verifyInventoryCountTest "sushi" 0 "$ORDER_ID (before placing order)"

placeOrderTest $ORDER_ID

echo "TEST_LOG: sleep for 10"
sleep 10

showOrderTest $ORDER_ID 'failed inventory does not exist'

addInventoryTest "sushi"

verifyInventoryCountTest "sushi" 1 "$ORDER_ID (after adding inventory)"

# Place second order 
ORDER_ID=$(($ORDER_ID + 1))

placeOrderTest "$ORDER_ID"

echo "TEST_LOG: sleep for 10"
sleep 10

showOrderTest "$ORDER_ID" 'success inventory exists'

verifyInventoryCountTest "sushi" 0 "$ORDER_ID"

if [[ $TEST_SERVICE != "" ]]
then
  echo writing log to $GRABDISH_LOG/testlog-$TEST_SERVICE
  logpodnotail $TEST_SERVICE > $GRABDISH_LOG/testlog-$TEST_SERVICE
fi
