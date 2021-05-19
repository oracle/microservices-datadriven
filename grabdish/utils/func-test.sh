#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

ORDER_ID="$1"

function order() {
  echo '{"serviceName": "order", "commandName": "'"$2"'", "orderId": '"$1"', "orderItem": "sushi", "deliverTo": "780 PANORAMA DR, San francisco, CA"}'
}

function inventory() {
  echo '{"serviceName": "supplier", "commandName": "'"$2"'", "orderId": "-1", "orderItem": '"$1"', "deliverTo": ""}'
}

function placeOrderTest() {
  # Place order
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(order "$1" 'placeOrder')" \
    --header='Content-Type: application/json' "$FRONTEND_URL/placeorder"; then
    echo "placeOrder $1 failed"
    return 1
  fi
}

function showOrderTest() {
  # Place order 
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(order "$1" 'showorder')" \
    --header='Content-Type: application/json' "$FRONTEND_URL/command" > $GRUBDASH_LOG/order; then
    echo "showOrder $1 failed"
    return 1
  fi

  echo $GRUBDASH_LOG/order
}


function addInventoryTest() {
  # Place order 
  if wget --http-user grabdish --http-password "$TEST_UI_PASSWORD" --no-check-certificate --post-data "$(inventory "$1" 'addInventory')" \
    --header='Content-Type: application/json' "$FRONTEND_URL/command"; then
    echo "showOrder $1 failed"
    return 1
  fi
}


# Show order and wait for status "no inventory"
placeOrderTest $ORDER_ID

sleep 5

showOrderTest $ORDER_ID 'no inventory'


# Add inventory
addInventoryTest "sushi"


# Place second order 
ORDER_ID=(($ORDER_ID + 1))

placeOrderTest "$ORDER_ID"

sleep 5

showOrderTest "$ORDER_ID" 'inventory exists'
