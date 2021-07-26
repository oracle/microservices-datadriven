#!/bin/bash
##
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -e

ORDER_COUNT="$1"

if [[ ! $LB =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Set variable LB to the external IP address of the ext-order service"
    exit
fi

./k6 run --vus 20 --iterations $ORDER_COUNT --address localhost:6566 --insecure-skip-tls-verify placeorder-perf.js