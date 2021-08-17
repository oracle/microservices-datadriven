#!/bin/bash
##
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -e

if [[ ! $LB =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Set variable LB to the external IP address of the ext-order service"
    exit
fi

NEXT_RUN_FILE=next_run

if [ ! -f "$NEXT_RUN_FILE" ]; then
    echo 0 > $NEXT_RUN_FILE
fi

export RUN=`cat $NEXT_RUN_FILE`
RUN=$((RUN+1))
echo $RUN > $NEXT_RUN_FILE

./k6 run --vus 20 --duration "30s" --address localhost:6566 --insecure-skip-tls-verify placeorder.js
