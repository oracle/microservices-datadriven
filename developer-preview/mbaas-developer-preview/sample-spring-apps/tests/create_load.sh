#!/bin/bash

## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

function create_customer () {
     curl -X POST -H 'Host: customer.com' -H 'Content-Type: application/json' -d '{"firstName": "jack", "lastName": "daniels", "email": "jack@jack.com"}'  http://localhost:9080/api/v1/customers
}

function fraud_check () {
    curl http://localhost:8081/api/v1/fraud-check/1
}

function send_notification () {
    curl -X POST -H 'Host: notify.com' -H 'Content-Type: application/json' -d '{"toCustomerId": 1, "toCustomerEmail": "bob@job.com", "message": "hi dave"}'   http://localhost:9080/api/v1/notify
}

function call_slow_service () {
    curl http://localhost:8077/fruit
}

function transfer () {
    curl  -X POST -H 'Content-Type: application/json' -d '{"fromAccount": "1", "toAccount": "2", "amount": 500}'   http://localhost:8077/transfer
}

##### entry point

echo 'Creating some load...'

while true; do

    X=$(( $RANDOM % 5 + 1 ))

    case $X in 
      1)
        create_customer
        ;;
      2)
        fraud_check
        ;;
      3) 
        send_notification
        ;;
      4)
        call_slow_service
        ;;
      *)
        transfer
        ;;
    esac

    sleep 0.5

done